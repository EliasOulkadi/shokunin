{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "nvidia": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "NVIDIA",
      "api": "https://integrate.api.nvidia.com/v1",
      "options": {
        "baseURL": "https://integrate.api.nvidia.com/v1",
        "timeout": 600000,
        "chunkTimeout": 60000
      },
      "models": {
        "moonshotai/kimi-k2.6": {
          "name": "Kimi K2.6",
          "reasoning": true,
          "tool_call": true,
          "temperature": true
        }
      }
    },
    "opencode-go": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "OpenCode Go",
      "api": "https://opencode.ai/zen/go/v1",
      "models": {
        "kimi-k2.6": { "name": "Kimi K2.6", "reasoning": true, "tool_call": true, "temperature": true },
        "deepseek-v4-pro": { "name": "DeepSeek V4 Pro", "reasoning": true, "tool_call": true, "temperature": true },
        "deepseek-v4-flash": { "name": "DeepSeek V4 Flash", "reasoning": true, "tool_call": true, "temperature": true },
        "glm-5": { "name": "GLM-5", "reasoning": true, "tool_call": true, "temperature": true },
        "glm-5.1": { "name": "GLM-5.1", "reasoning": true, "tool_call": true, "temperature": true },
        "mimo-v2.5": { "name": "MiMo-V2.5", "reasoning": true, "tool_call": true, "temperature": true },
        "mimo-v2.5-pro": { "name": "MiMo-V2.5-Pro", "reasoning": true, "tool_call": true, "temperature": true }
      }
    },
    "ollama": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Ollama (local)",
      "options": { "baseURL": "http://localhost:11434/v1" },
      "models": {
        "qwen3:14b": { "name": "Qwen3 14B" },
        "deepseek-coder:6.7b": { "name": "DeepSeek Coder 6.7B" },
        "qwen2.5-coder:7b": { "name": "Qwen2.5 Coder 7B" }
      }
    }
  },
  "plugin": [
    "superpowers@git+https://github.com/obra/superpowers.git"
  ],
  "mcp": {
    "filesystem": {
      "type": "local",
      "command": ["npx", "-y", "@modelcontextprotocol/server-filesystem", "{{MCP_ROOT_PATH}}"]
    },
    "fetch": {
      "type": "local",
      "command": ["npx", "-y", "@modelcontextprotocol/server-fetch"]
    },
    "memory": {
      "type": "local",
      "command": ["{{PYTHON_BIN}}", "{{MCP_MEMORY_PATH}}"]
    }
  },
  "agent": {
    "code-review-local": {
      "model": "ollama/qwen3:14b",
      "description": "Code review using local Ollama (offline fallback)",
      "mode": "subagent"
    },
    "debugger-local": {
      "model": "ollama/qwen3:14b",
      "description": "Deep debugging using local Ollama (offline fallback)",
      "mode": "subagent"
    },
    "code-review": {
      "model": "opencode-go/deepseek-v4-flash",
      "description": "Review code for bugs and security",
      "mode": "subagent"
    },
    "debugger": {
      "model": "opencode-go/deepseek-v4-flash",
      "description": "Deep debugging specialist",
      "mode": "subagent"
    }
  },
  "command": {
    "save": {
      "template": "Save the current session to ChromaDB memory.\n\nExecute python ~/.shokunin/scripts/chroma-helper.py session list 3 to see recent sessions.\n\nThen save this session with a properly structured session_end entry:\n\npython ~/.shokunin/scripts/chroma-helper.py save \"SESSION SUMMARY\n\n## Decisions\n- (list 3-7 key decisions made this session)\n\n## Files\n- (list 3-7 files modified with what changed)\n\n## Commands\n- (list 3-5 important commands executed)\n\n## Architecture\n- (any architectural insights or patterns used)\" auto session_end \"session-end,shokunin\" \"shokunin\"\n\nSummarize the output for the user showing what was saved.",
      "description": "Save current session to ChromaDB memory with structured context"
    },
    "load": {
      "template": "Load context from a previous session.\n\nFirst list recent sessions:\npython ~/.shokunin/scripts/chroma-helper.py session list 5\n\nShow the list to the user and ask which session to continue (by number).\nIf user picks a session, load it:\npython ~/.shokunin/scripts/chroma-helper.py session continue <session_id>\n\nPrint the decisions, files, commands found along with entry count.",
      "description": "List recent sessions and load context from a chosen one"
    },
    "status": {
      "template": "Run a full Shokunin ecosystem healthcheck.\n\nOn Windows:\n  & \"$env:USERPROFILE\\.shokunin\\scripts\\memory-healthcheck.ps1\"\n\nOn Linux:\n  bash ~/.shokunin/scripts/linux/memory-healthcheck.sh\n\nAlso check ecosystem drift:\n  & \"$env:USERPROFILE\\.shokunin\\scripts\\shokunin-update.ps1\" status\n\nSummarize results showing pass/fail counts and any warnings.",
      "description": "Run full Shokunin ecosystem healthcheck and drift detection"
    }
  }
}
