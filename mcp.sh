#!/usr/bin/env bash

set -euo pipefail

SERVER_NAME="bash-mcp"
SERVER_VERSION="0.2.0"

RESOURCE_FILE="/tmp/test.txt"

#
# Create demo resource file
#
echo "Hello from MCP resource file" >"$RESOURCE_FILE"

#
# Helpers
#
send_response() {
  local id="$1"
  local result="$2"

  jq -nc \
    --argjson id "$id" \
    --argjson result "$result" \
    '{
      jsonrpc: "2.0",
      id: $id,
      result: $result
    }'
}

send_error() {
  local id="$1"
  local code="$2"
  local message="$3"

  jq -nc \
    --argjson id "$id" \
    --argjson code "$code" \
    --arg message "$message" \
    '{
      jsonrpc: "2.0",
      id: $id,
      error: {
        code: $code,
        message: $message
      }
    }'
}

#
# Initialize
#
handle_initialize() {
  local id="$1"

  local result
  result=$(jq -nc \
    --arg name "$SERVER_NAME" \
    --arg version "$SERVER_VERSION" \
    '{
      protocolVersion: "2024-11-05",
      serverInfo: {
        name: $name,
        version: $version
      },
      capabilities: {
        tools: {},
        resources: {},
        prompts: {}
      }
    }')

  send_response "$id" "$result"
}

#
# Tools
#
handle_tools_list() {
  local id="$1"

  local result
  result=$(jq -nc '
    {
      tools: [
        {
          name: "hostname",
          description: "Get the hostname of the machine",
          inputSchema: {
            type: "object",
            properties: {},
            additionalProperties: false
          }
        },
        {
          name: "uptime",
          description: "Get the uptime of the machine",
          inputSchema: {
            type: "object",
            properties: {},
            additionalProperties: false
          }
        }
      ]
    }')

  send_response "$id" "$result"
}

handle_tool_call() {
  local id="$1"
  local tool_name="$2"

  case "$tool_name" in
  hostname)
    output=$(hostname)
    ;;

  uptime)
    output=$(uptime)
    ;;

  *)
    send_error "$id" -32601 "Unknown tool: $tool_name"
    return
    ;;
  esac

  local result
  result=$(jq -nc \
    --arg text "$output" '
    {
      content: [
        {
          type: "text",
          text: $text
        }
      ]
    }')

  send_response "$id" "$result"
}

#
# Resources
#
handle_resources_list() {
  local id="$1"

  local result
  result=$(jq -nc \
    --arg uri "file://$RESOURCE_FILE" '
    {
      resources: [
        {
          uri: $uri,
          name: "test-file",
          description: "Example resource file",
          mimeType: "text/plain"
        }
      ]
    }')

  send_response "$id" "$result"
}

handle_resources_read() {
  local id="$1"
  local uri="$2"

  if [[ "$uri" != "file://$RESOURCE_FILE" ]]; then
    send_error "$id" -32602 "Unknown resource: $uri"
    return
  fi

  content=$(cat "$RESOURCE_FILE")

  local result
  result=$(jq -nc \
    --arg uri "$uri" \
    --arg text "$content" '
    {
      contents: [
        {
          uri: $uri,
          mimeType: "text/plain",
          text: $text
        }
      ]
    }')

  send_response "$id" "$result"
}

#
# Prompts
#
handle_prompts_list() {
  local id="$1"

  local result
  result=$(jq -nc '
    {
      prompts: [
        {
          name: "sysinfo",
          description: "Generate a system diagnostics prompt",
          arguments: [
            {
              name: "topic",
              description: "Topic to investigate",
              required: true
            }
          ]
        }
      ]
    }')

  send_response "$id" "$result"
}

handle_prompts_get() {
  local id="$1"
  local prompt_name="$2"
  local topic="$3"

  if [[ "$prompt_name" != "sysinfo" ]]; then
    send_error "$id" -32602 "Unknown prompt: $prompt_name"
    return
  fi

  local prompt_text
  prompt_text="Please investigate the following Linux system topic: $topic"

  local result
  result=$(jq -nc \
    --arg desc "System investigation prompt" \
    --arg text "$prompt_text" '
    {
      description: $desc,
      messages: [
        {
          role: "user",
          content: {
            type: "text",
            text: $text
          }
        }
      ]
    }')

  send_response "$id" "$result"
}

#
# Main loop
#
while IFS= read -r line; do

  method=$(echo "$line" | jq -r '.method')
  id=$(echo "$line" | jq '.id')

  case "$method" in

  initialize)
    handle_initialize "$id"
    ;;

  tools/list)
    handle_tools_list "$id"
    ;;

  tools/call)
    tool_name=$(echo "$line" | jq -r '.params.name')
    handle_tool_call "$id" "$tool_name"
    ;;

  resources/list)
    handle_resources_list "$id"
    ;;

  resources/read)
    uri=$(echo "$line" | jq -r '.params.uri')
    handle_resources_read "$id" "$uri"
    ;;

  prompts/list)
    handle_prompts_list "$id"
    ;;

  prompts/get)
    prompt_name=$(echo "$line" | jq -r '.params.name')
    topic=$(echo "$line" | jq -r '.params.arguments.topic')

    handle_prompts_get "$id" "$prompt_name" "$topic"
    ;;

  *)
    send_error "$id" -32601 "Method not found: $method"
    ;;
  esac
done
