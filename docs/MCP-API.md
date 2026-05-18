# Shokunin Memory MCP Server API

Protocol: JSON-RPC 2.0
Transport: stdin/stdout
Version: 2024-11-05

## Tools

### store_context
Store text in persistent memory.
- `text` (string, required): Content to store
- `session_id` (string, required): Session identifier
- `type` (string, optional): `decision`|`file`|`command`|`preference`|`checkpoint`|`session_end`|`general`
- `tags` (string[], optional): Tags for categorization
- `project` (string, optional): Project name

### search_context
Vector similarity search.
- `query` (string, required): Search text
- `project` (string, optional): Filter by project
- `type` (string, optional): Filter by entry type
- `tags` (string[], optional): Filter by tags
- `n_results` (int, optional, default 10, max 50): Result count

### get_session_summary
Get all entries for a session.
- `session_id` (string, required)

### multi_search_context
Combined vector + BM25 + temporal filter search.
- `query` (string, required)
- `project` (string, optional)
- `n_results` (int, optional)
- `from_date` (string, optional, YYYY-MM-DD)
- `to_date` (string, optional, YYYY-MM-DD)

### consolidate_memories
Summarize old entries per project.
- `project` (string, optional): If empty, consolidates all

### list_sessions
Recent sessions list.
- `limit` (int, optional, max 20)
- `project` (string, optional)

### continue_session
Full context load for session resume.
- `session_id` (string, required)

### save_message
Record a message in session transcript.
- `text` (string, required)
- `session_id` (string, required)
- `role` (string, optional, default `"user"`)

## Example
```json
{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}
```
```bash
echo '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}' | python mcp-server.py
```
