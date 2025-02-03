version: 1.1.4
cache: true
interface:
  endpointsMenu: false
endpoints:
  custom:
    - name: "${openai_endpoint_name}"
      baseURL: "${openai_endpoint_base_url}"
      apiKey: "unused" #pragma: allowlist secret
      models:
        default: ["${openai_endpoint_default_model}"]
        fetch: true
      titleConvo: true
      titleModel: "current_model"
      summarize: false
      summaryModel: "current_model"
      forcePrompt: false
      modelDisplayLabel: "${openai_endpoint_display_name}"
