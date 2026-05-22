---
name: agent-tools
description: "Run 150+ AI apps via inference.sh CLI - image generation, video creation, LLMs, search, 3D, Twitter automation. Models: FLUX, Veo, Gemini, Grok, Claude, Seedance, OmniHuman, Tavily, Exa, OpenRouter, and many more. Use when running AI apps, generating images/videos, calling LLMs, web search, or automating Twitter. Triggers: inference.sh, infsh, ai model, run ai, serverless ai, ai api, flux, veo, claude api, image generation, video generation, openrouter, tavily, exa search, twitter api, grok"
triggers:
  - "inference.sh"
  - "infsh"
  - "FLUX"
  - "Veo"
  - "Gemini"
  - "Grok"
  - "Claude API"
  - "image generation"
  - "video generation"
  - "OpenRouter"
  - "Tavily"
  - "Exa"
  - "search API"
  - "AI model"
  - "run AI"
  - "serverless AI"
  - "Twitter API"
  - "social media automation"
negatives:
  - "local model"
  - "Ollama"
  - "vector search"
  - "memory"
  - "ChromaDB"
license: MIT
compatibility: opencode
allowed-tools: Bash(infsh *)
metadata:
  version: "1.0.0"

  workflow: ai-agents
  audience: developers
---


# [inference.sh](https://inference.sh)

Run 150+ AI apps in the cloud with a simple CLI. No GPU required.

![[inference.sh](https://inference.sh)](https://cloud.inference.sh/app/files/u/4mg21r6ta37mpaz6ktzwtt8krr/01kgjw8atdxgkrsr8a2t5peq7b.jpeg)

## Install CLI

```bash
curl -fsSL https://cli.inference.sh | sh
infsh login
```

> **What does the installer do?** The [install script](https://cli.inference.sh) detects your OS and architecture, downloads the correct binary from `dist.inference.sh`, verifies its SHA-256 checksum, and places it in your PATH. That's it — no elevated permissions, no background processes, no telemetry. If you have [cosign](https://docs.sigstore.dev/cosign/system_config/installation/) installed, the installer also verifies the Sigstore signature automatically.
>
> **Manual install** (if you prefer not to pipe to sh):
> ```bash
> # Download the binary and checksums
> curl -LO https://dist.inference.sh/cli/checksums.txt
> curl -LO $(curl -fsSL https://dist.inference.sh/cli/manifest.json | grep -o '"url":"[^"]*"' | grep $(uname -s | tr A-Z a-z)-$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/') | head -1 | cut -d'"' -f4)
> # Verify checksum
> sha256sum -c checksums.txt --ignore-missing
> # Extract and install
> tar -xzf inferencesh-cli-*.tar.gz
> mv inferencesh-cli-* ~/.local/bin/inferencesh
> ```

## Quick Examples

```bash
# Generate an image
infsh app run falai/flux-dev-lora --input '{"prompt": "a cat astronaut"}'

# Generate a video
infsh app run google/veo-3-1-fast --input '{"prompt": "drone over mountains"}'

# Call Claude
infsh app run openrouter/claude-sonnet-45 --input '{"prompt": "Explain quantum computing"}'

# Web search
infsh app run tavily/search-assistant --input '{"query": "latest AI news"}'

# Post to Twitter
infsh app run x/post-tweet --input '{"text": "Hello from AI!"}'

# Generate 3D model
infsh app run infsh/rodin-3d-generator --input '{"prompt": "a wooden chair"}'
```

## Local File Uploads

The CLI automatically uploads local files when you provide a path instead of a URL:

```bash
# Upscale a local image
infsh app run falai/topaz-image-upscaler --input '{"image": "/path/to/photo.jpg", "upscale_factor": 2}'

# Image-to-video from local file
infsh app run falai/wan-2-5-i2v --input '{"image": "./my-image.png", "prompt": "make it move"}'

# Avatar with local audio and image
infsh app run bytedance/omnihuman-1-5 --input '{"audio": "/path/to/speech.mp3", "image": "/path/to/face.jpg"}'

# Post tweet with local media
infsh app run x/post-create --input '{"text": "Check this out!", "media": "./screenshot.png"}'
```

## Commands

| Task | Command |
|------|---------|
| List all apps | `infsh app list` |
| Search apps | `infsh app list --search "flux"` |
| Filter by category | `infsh app list --category image` |
| Get app details | `infsh app get google/veo-3-1-fast` |
| Generate sample input | `infsh app sample google/veo-3-1-fast --save input.json` |
| Run app | `infsh app run google/veo-3-1-fast --input input.json` |
| Run without waiting | `infsh app run <app> --input input.json --no-wait` |
| Check task status | `infsh task get <task-id>` |

## What's Available

| Category | Examples |
|----------|----------|
| **Image** | FLUX, Gemini 3 Pro, Grok Imagine, Seedream 4.5, Reve, Topaz Upscaler |
| **Video** | Veo 3.1, Seedance 1.5, Wan 2.5, OmniHuman, Fabric, HunyuanVideo Foley |
| **LLMs** | Claude Opus/Sonnet/Haiku, Gemini 3 Pro, Kimi K2, GLM-4, any OpenRouter model |
| **Search** | Tavily Search, Tavily Extract, Exa Search, Exa Answer, Exa Extract |
| **3D** | Rodin 3D Generator |
| **Twitter/X** | post-tweet, post-create, dm-send, user-follow, post-like, post-retweet |
| **Utilities** | Media merger, caption videos, image stitching, audio extraction |

## Related Skills

```bash
# Image generation (FLUX, Gemini, Grok, Seedream)
npx skills add inference-sh/skills@ai-image-generation

# Video generation (Veo, Seedance, Wan, OmniHuman)
npx skills add inference-sh/skills@ai-video-generation

# LLMs (Claude, Gemini, Kimi, GLM via OpenRouter)
npx skills add inference-sh/skills@llm-models

# Web search (Tavily, Exa)
npx skills add inference-sh/skills@web-search

# AI avatars & lipsync (OmniHuman, Fabric, PixVerse)
npx skills add inference-sh/skills@ai-avatar-video

# Twitter/X automation
npx skills add inference-sh/skills@twitter-automation

# Model-specific
npx skills add inference-sh/skills@flux-image
npx skills add inference-sh/skills@google-veo

# Utilities
npx skills add inference-sh/skills@image-upscaling
npx skills add inference-sh/skills@background-removal
```

## Reference Files

- [Authentication & Setup](references/authentication.md)
- [Discovering Apps](references/app-discovery.md)
- [Running Apps](references/running-apps.md)
- [CLI Reference](references/cli-reference.md)

## Documentation

- [Agent Skills Overview](https://inference.sh/blog/skills/skills-overview) - The open standard for AI capabilities
- [Getting Started](https://inference.sh/docs/getting-started/introduction) - Introduction to inference.sh
- [What is inference.sh?](https://inference.sh/docs/getting-started/what-is-inference) - Platform overview
- [Apps Overview](https://inference.sh/docs/apps/overview) - Understanding the app ecosystem
- [CLI Setup](https://inference.sh/docs/extend/cli-setup) - Installing the CLI
- [Workflows vs Agents](https://inference.sh/blog/concepts/workflows-vs-agents) - When to use each
- [Why Agent Runtimes Matter](https://inference.sh/blog/agent-runtime/why-runtimes-matter) - Runtime benefits

## Workflow

1. **Discover** — `infsh app list --search "<keyword>"` or `infsh app list --category <image|video|llm|search|3d|x|utility>` to find the right app
2. **Inspect** — `infsh app get <app-id>` for description, pricing, input schema, and rate limits
3. **Generate sample input** — `infsh app sample <app-id> --save input.json` to get a valid input template pre-filled with defaults
4. **Customize** — edit the JSON input file: replace prompts, file paths, or configuration values
5. **Run** — `infsh app run <app-id> --input input.json` for synchronous execution, or `--no-wait` for long-running tasks
6. **Check status** — `infsh task get <task-id>` to poll progress of async tasks; `infsh task logs <task-id>` for streaming output
7. **Retrieve output** — outputs are URLs (images, videos) or text responses; download with `infsh task download <task-id>`

For multi-step pipelines, chain apps: run the first app, extract its output URL, feed it as input to the next app (e.g., generate image → upscale, or generate video → add audio).

## Error Handling

| Error | Cause | Fix |
|-------|-------|-----|
| `infsh: command not found` | CLI not installed or not in PATH | Run `curl -fsSL https://cli.inference.sh | sh` or check PATH includes the install directory |
| `401 Unauthorized` | Not logged in or token expired | Run `infsh login` and re-authenticate |
| `402 Payment Required` | Account has no credits or payment method | Check `infsh billing`; add credits via inference.sh dashboard |
| `429 Too Many Requests` | Rate limit exceeded for the app or account tier | Wait for the `Retry-After` header duration; for paid tiers, request a limit increase |
| `400 Bad Request` on file upload | File path does not exist, is a directory, or exceeds size limits | Verify the file path with `ls -la`; check the app's max input size in `infsh app get <app-id>` |
| `Task timed out` (HTTP 504 or task status `failed`) | App execution exceeded max duration | Check `infsh task get <task-id>` for error details; retry with smaller input or check app status page |
| `502 Bad Gateway` or connection errors | inference.sh backend or model provider is down | Check https://status.inference.sh; retry with exponential backoff (2s, 4s, 8s) |
| Output URL returns 404 | Generated asset expired (files are ephemeral) | Re-run the job; for permanent storage, download immediately with `infsh task download <task-id>` |
| JSON parse error on `--input` | Input file is not valid JSON or schema mismatch | Use `infsh app sample <app-id> --save input.json` to regenerate a valid template |
| Image/video generation produces blank or corrupted output | Model inference failed silently | Re-run the job; check app-specific known issues in `infsh app get <app-id>`; try a different model for the same task |

## Checklist

- [ ] App is authenticated before running (`infsh login check`)
- [ ] Model supports the requested input format (image/video/text sizes)
- [ ] Task ID saved for async operations to retrieve results later
- [ ] Credit cost checked before bulk operations
- [ ] Output format confirmed (URL, file, or stdout) before passing to next step

## Sources

- [inference.sh CLI documentation](https://cli.inference.sh) — installation, commands, authentication
- [inference.sh Apps Catalog](https://inference.sh/apps) — full app library with schemas and examples
- [OpenRouter API](https://openrouter.ai/docs) — LLM model routing and pricing
- FLUX documentation (fal.ai, replicate.com) — image generation parameters and best practices
- Veo API (Google DeepMind) — video generation capabilities and limitations
- Tavily Search API (tavily.com) — web search and extraction endpoints
- Exa API (exa.ai) — semantic search and content extraction
- x.com Developer API — Twitter/X posting, DMs, and engagement endpoints

## Anti-Patterns

| Anti-pattern | Why it fails | Fix |
|-------------|-------------|-----|
| Not checking `infsh app get` before running | Input schema varies between apps; guessing fields causes 400 errors | Always run `infsh app sample` first to see the exact schema |
| Hardcoding file paths without verifying they exist | The CLI auto-uploads relative paths; missing files produce confusing errors | Use absolute paths or verify relative paths with `Test-Path` before running |
| Not using `--no-wait` for long-running tasks | Synchronous runs block the terminal for minutes on video/3D generation | Use `--no-wait` and poll with `infsh task get <id>` for tasks expected to take > 30s |
| Ignoring rate limits and credit costs | Each app has different pricing; some cost $0.50+ per run | Check `infsh app get <app-id>` for cost estimate before bulk/generating runs |
| Using the cheapest model for everything | OpenRouter free models may have lower quality or stricter rate limits | Match model quality to task importance; paid tiers are more reliable |
| Not saving task IDs | Async tasks complete after the terminal session; without the ID you can't retrieve results | Log all task IDs: `infsh task get <id> > task-<id>-result.json` |
| Running image generation without checking supported resolutions/aspect ratios | Models silently crop or stretch to supported dimensions | Check `infsh app get` for `supported_sizes` or `aspect_ratios` field |
