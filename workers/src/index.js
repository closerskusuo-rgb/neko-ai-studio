
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type",
};

function json(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}

export default {
  async fetch(request, env) {
    if (request.method === "OPTIONS") {
      return new Response(null, {
        status: 204,
        headers: corsHeaders,
      });
    }

    const url = new URL(request.url);

    if (request.method === "GET" && (url.pathname === "/" || url.pathname === "/health")) {
      return json({
        success: true,
        service: "Neko AI Studio Backend",
        status: "online",
      });
    }

    if (request.method !== "POST" || url.pathname !== "/generate") {
      return json({ success: false, error: "Endpoint tidak ditemukan." }, 404);
    }

    try {
      const contentLength = Number(request.headers.get("content-length") || 0);
      if (contentLength > 20000) {
        return json({ success: false, error: "Permintaan terlalu besar." }, 413);
      }

      const body = await request.json();

      const prompt = String(body.prompt || "").trim();
      const negativePrompt = String(body.negativePrompt || "").trim();
      const style = String(body.style || "Anime").trim();
      const ratio = String(body.ratio || "1:1").trim();

      if (!prompt) {
        return json({ success: false, error: "Prompt tidak boleh kosong." }, 400);
      }

      if (prompt.length > 1800 || negativePrompt.length > 500) {
        return json({ success: false, error: "Prompt terlalu panjang." }, 400);
      }

      const finalPrompt = [
        prompt,
        `Art style: ${style}.`,
        `Composition aspect ratio: ${ratio}.`,
        negativePrompt ? `Avoid these elements: ${negativePrompt}.` : "",
      ].filter(Boolean).join(" ");

      const result = await env.AI.run(
        "@cf/black-forest-labs/flux-1-schnell",
        {
          prompt: finalPrompt,
          steps: 4,
        }
      );

      if (!result || !result.image) {
        return json({
          success: false,
          error: "Model tidak mengembalikan gambar.",
        }, 502);
      }

      return json({
        success: true,
        image: result.image,
      });

    } catch (error) {
      return json({
        success: false,
        error: "Gagal membuat gambar. Coba lagi nanti.",
      }, 500);
    }
  },
};
