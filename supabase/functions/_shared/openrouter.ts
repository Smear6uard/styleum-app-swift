// Shared OpenRouter client for all edge functions

export interface OpenRouterMessage {
  role: "system" | "user" | "assistant";
  content: string | OpenRouterContent[];
}

export interface OpenRouterContent {
  type: "text" | "image_url";
  text?: string;
  image_url?: {
    url: string;
  };
}

export interface OpenRouterResponse {
  choices: {
    message: {
      content: string;
    };
  }[];
  usage?: {
    prompt_tokens: number;
    completion_tokens: number;
    total_tokens: number;
  };
}

export async function callOpenRouter(
  model: string,
  messages: OpenRouterMessage[],
  options: {
    temperature?: number;
    max_tokens?: number;
    response_format?: { type: "json_object" };
  } = {}
): Promise<OpenRouterResponse> {
  const apiKey = Deno.env.get("OPENROUTER_API_KEY");
  if (!apiKey) {
    throw new Error("Missing OPENROUTER_API_KEY");
  }

  const response = await fetch("https://openrouter.ai/api/v1/chat/completions", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${apiKey}`,
      "Content-Type": "application/json",
      "HTTP-Referer": "https://styleum.app",
      "X-Title": "Styleum Fashion AI",
    },
    body: JSON.stringify({
      model,
      messages,
      temperature: options.temperature ?? 0.3,
      max_tokens: options.max_tokens ?? 2048,
      response_format: options.response_format,
    }),
  });

  if (!response.ok) {
    const error = await response.text();
    console.error(`OpenRouter error (${model}):`, error);
    throw new Error(`OpenRouter API error: ${response.status}`);
  }

  return await response.json();
}

// Model constants - Gemini via OpenRouter
export const MODELS = {
  // Primary model - use for most tasks
  GEMINI_FLASH_LITE: "google/gemini-2.5-flash-lite-preview-09-2025",

  // Fallback for complex reasoning
  GEMINI_FLASH: "google/gemini-2.5-flash",
} as const;

// Helper to extract JSON from response text
export function extractJSON<T>(text: string): T {
  const jsonMatch = text.match(/[\[{][\s\S]*[\]}]/);
  if (!jsonMatch) {
    throw new Error("No JSON found in response");
  }
  return JSON.parse(jsonMatch[0]);
}
