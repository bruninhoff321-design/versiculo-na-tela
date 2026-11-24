// O app chama esta função com o e-mail da compra. Se a compra existir e
// estiver ativa, libera o app (até 3 celulares por compra).
import { createClient } from "jsr:@supabase/supabase-js@2";

const LIMITE_APARELHOS = 3;

const db = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

const json = (dados: unknown, status = 200) =>
  new Response(JSON.stringify(dados), {
    status,
    headers: { "content-type": "application/json" },
  });

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ ok: false, motivo: "método" }, 405);
  let body: any;
  try {
    body = await req.json();
  } catch {
    return json({ ok: false, motivo: "json" }, 400);
  }
  const email = String(body?.email ?? "").trim().toLowerCase();
  const aparelho = String(body?.aparelho ?? "").trim();
  if (!email || !aparelho) return json({ ok: false, motivo: "dados" }, 400);

  const { data, error } = await db
    .from("compras").select("*").eq("email", email).maybeSingle();
  if (error) return json({ ok: false, motivo: "erro" }, 500);
  if (!data) return json({ ok: false, motivo: "nao_encontrado" });
  if (data.status !== "ativo") return json({ ok: false, motivo: "cancelado" });

  const aparelhos: string[] = data.aparelhos ?? [];
  if (!aparelhos.includes(aparelho)) {
    if (aparelhos.length >= LIMITE_APARELHOS) {
      return json({ ok: false, motivo: "limite" });
    }
    aparelhos.push(aparelho);
    await db.from("compras").update({ aparelhos }).eq("email", email);
  }
  return json({ ok: true });
});
