# PROTOCOLO Z

Jogo mobile de sobrevivência pós-apocalíptica desenvolvido em Flutter e Supabase.

## O que já está incluído nesta primeira base

- Splash com direcionamento por sessão e facção.
- Cadastro e login com Supabase Auth.
- Perfil criado automaticamente por trigger.
- Escolha definitiva de facção com kit inicial concedido no servidor.
- Central de sobrevivência com reputação e facção.
- Inventário com filtro por categoria.
- Expedições com duração persistida no banco e resgate validado pelo servidor.
- Perfil com logout.
- Tema escuro e widgets reutilizáveis.

## Requisitos

- Flutter estável (3.24 ou superior recomendado).
- Dart compatível com o SDK do Flutter.
- Projeto Supabase.
- Android Studio ou VS Code com extensão Flutter.

## Configuração do Supabase

1. Crie um projeto em https://supabase.com.
2. Abra SQL Editor no painel do Supabase.
3. Execute o arquivo `supabase/migrations/001_initial_schema.sql`.
4. Em Authentication > URL Configuration, configure os endereços permitidos para seu app, se necessário.
5. Em Authentication > Providers > Email, escolha se a confirmação de e-mail ficará habilitada.
6. Copie Project URL e anon/publishable key do painel.

## Configurar e executar

No terminal, dentro da pasta do projeto:

```bash
flutter pub get
flutter run --dart-define=SUPABASE_URL=https://SEU-PROJETO.supabase.co --dart-define=SUPABASE_ANON_KEY=SUA_CHAVE_PUBLICA
```

Nunca coloque `service_role` no aplicativo Flutter. A chave pública é protegida pelas políticas RLS; operações privilegiadas devem ficar em funções SQL ou Edge Functions.

## Estrutura

```text
lib/
  core/          configuração e tema
  models/        modelos de dados
  repositories/  acesso ao Supabase
  screens/       telas
  widgets/       componentes reutilizáveis
supabase/
  migrations/    estrutura e funções SQL
```

## Regras de reputação nesta base

| Ação | Pontos |
|---|---:|
| Concluir expedição | +10 |
| Cadastrar abrigo | +15 (módulo de abrigos a implementar) |
| Concluir troca | +20 para cada jogador (módulo de trocas a implementar) |
| Alerta confirmado por dois jogadores | +25 (módulo de alertas a implementar) |

## Próximos módulos

Esta é a primeira entrega funcional de fundação, não a implementação final de todos os requisitos. Ainda precisam ser concluídos: mapa e abrigos com GPS/fotos, trocas atômicas, alertas em tempo real, confirmações, ranking, avatar no Storage, estatísticas de perfil, notificações e testes automatizados.

## Observações de segurança

- RLS está habilitado nas tabelas.
- Facção é atribuída por RPC e não pode ser trocada pelo cliente.
- Kit inicial e recompensas são concedidos no banco.
- A duração da expedição é validada pelo relógio do servidor.
- Antes de publicar, revisar as policies de produção e adicionar testes para todas as RPCs.


## Recursos do dispositivo

- `flutter_map` + OpenStreetMap: mapa sem chave de API.
- `geolocator`: tenta obter GPS; com permissão negada, o jogador continua escolhendo um ponto pelo toque no mapa.
- `image_picker`: câmera e galeria para fotos de abrigo.
- Supabase Storage: buckets `shelter-photos` e `avatars`; perfil permite trocar avatar pela câmera ou galeria.
- Reputação de abrigo é concedida por trigger no banco, atomicamente após o cadastro.

### Configuração adicional

1. Execute `supabase/storage_setup.sql` no SQL Editor do Supabase.
2. Execute `flutter pub get`.
3. Android: permissões de internet e localização estão em `android/app/src/main/AndroidManifest.xml`.
4. iOS: copie as descrições de `ios/InfoPlist_permissions.txt` para `ios/Runner/Info.plist`.
5. Abra "Mapa e abrigos" pela Home.

O mapa inicia em Caçapava como coordenada demonstrativa. Altere `_initial` em `ShelterMapScreen` para outro ponto inicial. A atribuição OpenStreetMap aparece no mapa; em produção, respeite a política de uso dos servidores de tiles e escolha provedor adequado para tráfego elevado.
