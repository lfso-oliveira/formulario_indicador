/**
 * Formulário público: copie para `config.js` e preencha (Project URL + anon key).
 * A chave anon só precisa de permissão de INSERT na tabela `indicadores_envios`.
 *
 * A página `/admin/` usa o mesmo ficheiro: precisa de política SELECT no
 * Supabase (ver schema.sql). Não use service_role no browser.
 */
window.INDICADORES_SUPABASE = {
  url: "https://SEU-PROJETO.supabase.co",
  anonKey: "SUA-CHAVE-ANON-PUBLICA",
};
