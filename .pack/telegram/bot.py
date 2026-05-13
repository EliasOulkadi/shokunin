import asyncio
import json
import logging
import os
import re
import sys
import urllib.request
import urllib.error
from datetime import datetime, timezone
from glob import iglob
from pathlib import Path
from typing import Optional

from telegram import Update, BotCommand
from telegram.ext import Application, CommandHandler, ContextTypes

logging.basicConfig(
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    level=logging.INFO,
)
log = logging.getLogger(__name__)

BASE_DIR = Path(__file__).resolve().parent
MEMORY_DIR = BASE_DIR.parent / "memory" / "sessions"
QUEUE_FILE = BASE_DIR / "queue.jsonl"
OPENCODE_API = os.environ.get("OPENCODE_API_URL", "http://localhost:5172/api/chat")

BOT_START = datetime.now(timezone.utc)
SKILLS_DIRS = [
    Path(p)
    for p in (
        os.environ.get("AGENTS_DIR", str(Path.home() / ".agents" / "skills")),
        str(Path.home() / ".config" / "opencode" / "skills"),
    )
]

BACKUP_FILE = BASE_DIR / "backup" / "last_backup.txt"


def _load_skills_count() -> int:
    seen = set()
    for d in SKILLS_DIRS:
        if d.is_dir():
            for entry in d.iterdir():
                if entry.is_dir() and not entry.name.startswith("_"):
                    seen.add(entry.name)
    return len(seen)


def _load_last_backup() -> str:
    if BACKUP_FILE.is_file():
        raw = BACKUP_FILE.read_text(encoding="utf-8").strip()
        if raw:
            return raw
    return "Nunca"


def _uptime() -> str:
    delta = datetime.now(timezone.utc) - BOT_START
    parts = []
    if delta.days:
        parts.append(f"{delta.days}d")
    h, r = divmod(delta.seconds, 3600)
    m, s = divmod(r, 60)
    if h:
        parts.append(f"{h}h")
    if m:
        parts.append(f"{m}m")
    parts.append(f"{s}s")
    return " ".join(parts)


def _call_opencode_api(question: str) -> Optional[str]:
    payload = json.dumps({"message": question}).encode("utf-8")
    req = urllib.request.Request(
        OPENCODE_API,
        data=payload,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            return data.get("response") or data.get("reply") or data.get("answer") or json.dumps(data)
    except urllib.error.HTTPError as e:
        log.warning("OpenCode API returned HTTP %s: %s", e.code, e.reason)
        return None
    except urllib.error.URLError as e:
        log.warning("OpenCode API unreachable: %s", e.reason)
        return None
    except (OSError, json.JSONDecodeError) as e:
        log.warning("OpenCode API error: %s", e)
        return None


def _queue_question(question: str, user_id: int) -> None:
    QUEUE_FILE.parent.mkdir(parents=True, exist_ok=True)
    entry = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "user_id": user_id,
        "question": question,
    }
    with QUEUE_FILE.open("a", encoding="utf-8") as f:
        f.write(json.dumps(entry, ensure_ascii=False) + "\n")


def _search_memory(query: str, limit: int = 5) -> list[dict]:
    results: list[dict] = []
    if not MEMORY_DIR.is_dir():
        return results

    terms = query.lower().split()
    for fp in sorted(iglob(str(MEMORY_DIR / "**" / "*.md"), recursive=True)):
        try:
            text = Path(fp).read_text(encoding="utf-8")
        except Exception:
            continue

        score = sum(text.lower().count(t) for t in terms)
        if score == 0:
            continue

        preview = text[:240].replace("\n", " ").strip()
        if len(text) > 240:
            preview += "…"

        results.append({
            "file": Path(fp).relative_to(MEMORY_DIR).as_posix(),
            "score": score,
            "preview": preview,
        })

    results.sort(key=lambda r: r["score"], reverse=True)
    return results[:limit]


async def _error_handler(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    log.exception("Unhandled exception in handler")
    if update and update.effective_message:
        await update.effective_message.reply_text(
            "Algo salió mal. Intentá de nuevo más tarde."
        )


async def cmd_start(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    await update.message.reply_text(
        "🤖 *Shokunin Bot*\n\n"
        "Soy el puente entre Telegram y el ecosistema OpenCode.\n\n"
        "Comandos:\n"
        "• `/ask [pregunta]` — Consultá a OpenCode\n"
        "• `/status` — Estado del sistema\n"
        "• `/memory [query]` — Buscá en la memoria del asistente\n"
        "• `/help` — Lista completa de comandos\n\n"
        "¿En qué te ayudo?",
        parse_mode="Markdown",
    )


async def cmd_help(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    await update.message.reply_text(
        "*/ask [pregunta]* — Enviá una pregunta a OpenCode. "
        "Si el servicio no está disponible, se encola para después.\n\n"
        "*/status* — Mostrá skills instaladas, uptime del bot y "
        "último backup.\n\n"
        "*/memory [términos]* — Buscá en archivos de sesiones "
        "anteriores guardados en markdown.\n\n"
        "*/start* — Mensaje de bienvenida.\n\n"
        "*/help* — Esta ayuda.",
        parse_mode="Markdown",
    )


async def cmd_ask(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    question = " ".join(context.args) if context.args else ""
    if not question:
        await update.message.reply_text(
            "Usá: `/ask [tu pregunta]`",
            parse_mode="Markdown",
        )
        return

    msg = await update.message.reply_text("🔍 Consultando a OpenCode…")
    answer = await asyncio.to_thread(_call_opencode_api, question)

    if answer:
        # Truncate if too long (Telegram limit: 4096 chars)
        if len(answer) > 4000:
            answer = answer[:3997] + "…"
        await msg.edit_text(answer)
    else:
        _queue_question(question, update.effective_user.id)
        await msg.edit_text(
            "OpenCode no está disponible en este momento. "
            "Tu pregunta fue encolada y se procesará cuando "
            "el servicio esté activo."
        )


async def cmd_status(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    skills = _load_skills_count()
    uptime = _uptime()
    backup = _load_last_backup()

    lines = [
        "*Estado del sistema*\n",
        f"• Skills instaladas: `{skills}`",
        f"• Uptime del bot: `{uptime}`",
        f"• Último backup: `{backup}`",
        f"• Cola de preguntas: `{sum(1 for _ in _queue_iter())}` pendientes",
    ]
    if MEMORY_DIR.is_dir():
        mem_count = sum(1 for _ in iglob(str(MEMORY_DIR / "**" / "*.md"), recursive=True))
        lines.append(f"• Archivos de memoria: `{mem_count}`")

    await update.message.reply_text(
        "\n".join(lines),
        parse_mode="Markdown",
    )


def _queue_iter():
    if not QUEUE_FILE.is_file():
        return
    with QUEUE_FILE.open("r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line:
                yield line


async def cmd_memory(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    query = " ".join(context.args) if context.args else ""
    if not query:
        await update.message.reply_text(
            "Usá: `/memory [términos de búsqueda]`",
            parse_mode="Markdown",
        )
        return

    msg = await update.message.reply_text("🔎 Buscando en la memoria…")

    try:
        results = await asyncio.to_thread(_search_memory, query)
    except Exception:
        log.exception("Memory search failed")
        await msg.edit_text("Error al buscar en la memoria.")
        return

    if not results:
        await msg.edit_text("No se encontraron resultados en la memoria.")
        return

    lines = [f"*Resultados para:* _{query}_\n"]
    for r in results:
        lines.append(f"• `{r['file']}` (coincidencias: {r['score']})")
        lines.append(f"  {r['preview']}\n")

    text = "\n".join(lines)
    if len(text) > 4000:
        text = text[:3997] + "…"

    await msg.edit_text(text, parse_mode="Markdown")


async def cmd_unknown(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    cmd = update.message.text.split()[0] if update.message.text else ""
    await update.message.reply_text(
        f"Comando desconocido: `{cmd}`\n"
        "Usá `/help` para ver los comandos disponibles.",
        parse_mode="Markdown",
    )


async def post_init(app: Application) -> None:
    cmds = [
        BotCommand("ask", "Consultar a OpenCode"),
        BotCommand("status", "Estado del sistema"),
        BotCommand("memory", "Buscar en la memoria"),
        BotCommand("help", "Ayuda"),
        BotCommand("start", "Bienvenida"),
    ]
    await app.bot.set_my_commands(cmds)


def main() -> None:
    token = os.environ.get("TELEGRAM_BOT_TOKEN")
    if not token:
        log.error("TELEGRAM_BOT_TOKEN no está definido en las variables de entorno.")
        sys.exit(1)

    app = (
        Application.builder()
        .token(token)
        .post_init(post_init)
        .build()
    )

    app.add_handler(CommandHandler("start", cmd_start))
    app.add_handler(CommandHandler("help", cmd_help))
    app.add_handler(CommandHandler("ask", cmd_ask))
    app.add_handler(CommandHandler("status", cmd_status))
    app.add_handler(CommandHandler("memory", cmd_memory))
    app.add_error_handler(_error_handler)

    log.info("Bot iniciado — polling activo")
    app.run_polling(allowed_updates=Update.ALL_TYPES)


if __name__ == "__main__":
    main()
