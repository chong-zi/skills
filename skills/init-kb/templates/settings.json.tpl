{
  "hooks": {
    "UserPromptSubmit": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "{{TARGET_DIR}}/skills/kb/kb-update.sh"
          }
        ]
      }
    ]
  }
}
