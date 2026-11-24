// Recebe o aviso da Cakto quando uma venda é aprovada, reembolsada ou
// estornada, e guarda o e-mail de quem comprou.
import { createClient } from "jsr:@supabase/supabase-js@2";

const db = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

Deno.serve(async (req) => {
  if (req.method !== "POST") return new Response("ok");
  let body: any;
  try {
    body = await req.json();
  } catch {
    return new Response("json inválido", { status: 400 });
  }

  // A Cakto manda a "chave secreta" do webhook junto com cada aviso.
  if (body?.secret !== Deno.env.get("CAKTO_SECRET")) {
    return new Response("não autorizado", { status: 401 });
  }

  const email = String(body?.data?.customer?.email ?? "").trim().toLowerCase();
  if (!email) return new Response("sem e-mail", { status: 400 });

  const evento = String(body?.event ?? "");
  let status: string | null = null;
  if (evento === "purchase_approved") status = "ativo";
  if (evento === "refund" || evento === "chargeback") status = "cancelado";
  if (!status) return new Response("evento ignorado");

  const { error } = await db.from("compras").upsert({
    email,
    status,
    pedido: String(body?.data?.refId ?? body?.data?.id ?? ""),
    atualizado: new Date().toISOString(),
  }, { onConflict: "email" });

  if (error) return new Response(error.message, { status: 500 });
  return new Response("ok");
});
