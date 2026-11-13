create extension if not exists pgcrypto;

create table public.factions (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  symbol text not null,
  color text not null,
  description text not null
);

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  nickname text not null,
  avatar_url text,
  faction_id uuid references public.factions(id),
  reputation integer not null default 0 check (reputation >= 0),
  created_at timestamptz not null default now()
);

create table public.items (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  category text not null check (category in ('agua','comida','medicamentos','ferramentas','combustivel')),
  icon text not null default '📦'
);

create table public.inventory (
  player_id uuid references public.profiles(id) on delete cascade,
  item_id uuid references public.items(id),
  quantity integer not null default 0 check (quantity >= 0),
  primary key (player_id, item_id)
);

create table public.expedition_types (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  duration_seconds integer not null check (duration_seconds between 60 and 300),
  risk text not null check (risk in ('baixo','medio','alto')),
  active boolean not null default true
);

create table public.expeditions (
  id uuid primary key default gen_random_uuid(),
  player_id uuid not null references public.profiles(id) on delete cascade,
  expedition_type_id uuid not null references public.expedition_types(id),
  started_at timestamptz not null default now(),
  ends_at timestamptz not null,
  status text not null default 'in_progress' check (status in ('in_progress','completed','claimed','failed')),
  created_at timestamptz not null default now()
);

create unique index one_active_expedition_per_player
on public.expeditions(player_id) where status = 'in_progress';

create table public.shelters (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references public.profiles(id),
  faction_id uuid references public.factions(id),
  name text not null,
  description text not null,
  capacity integer not null check (capacity > 0),
  photo_url text,
  latitude double precision not null,
  longitude double precision not null,
  visibility text not null check (visibility in ('public','faction')),
  status text not null default 'safe' check (status in ('safe','compromised')),
  created_at timestamptz not null default now()
);

create table public.trades (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references public.profiles(id),
  recipient_id uuid not null references public.profiles(id),
  status text not null default 'pending' check (status in ('pending','accepted','refused','cancelled','expired')),
  expires_at timestamptz not null default (now() + interval '24 hours'),
  created_at timestamptz not null default now(),
  check (author_id <> recipient_id)
);

create table public.trade_items (
  id uuid primary key default gen_random_uuid(),
  trade_id uuid not null references public.trades(id) on delete cascade,
  player_side text not null check (player_side in ('offered','requested')),
  item_id uuid not null references public.items(id),
  quantity integer not null check (quantity > 0)
);

create table public.horde_alerts (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references public.profiles(id),
  latitude double precision not null,
  longitude double precision not null,
  intensity text not null check (intensity in ('baixa','media','alta')),
  description text not null,
  expires_at timestamptz not null default (now() + interval '30 minutes'),
  created_at timestamptz not null default now()
);

create table public.alert_confirmations (
  alert_id uuid not null references public.horde_alerts(id) on delete cascade,
  player_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (alert_id, player_id)
);

create or replace function public.create_profile_for_new_user()
returns trigger language plpgsql security definer set search_path = public
as $$
begin
  insert into public.profiles(id, nickname)
  values (new.id, coalesce(nullif(new.raw_user_meta_data->>'nickname',''), split_part(new.email,'@',1)));
  return new;
end;
$$;

create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.create_profile_for_new_user();

insert into public.factions(name,symbol,color,description) values
('Sentinelas','🛡','#78945E','Especialistas em defesa, proteção e construção de abrigos.'),
('Catadores','⚒','#D18B45','Exploradores que recuperam recursos em zonas perigosas.'),
('Renascidos','✚','#5B9BC2','Especialistas em medicina, pesquisa e recuperação.')
on conflict (name) do nothing;

insert into public.items(name,category,icon) values
('Água potável','agua','💧'),('Comida enlatada','comida','🥫'),
('Kit médico','medicamentos','🩹'),('Sucata','ferramentas','🔧'),
('Combustível','combustivel','⛽')
on conflict (name) do nothing;

insert into public.expedition_types(name,duration_seconds,risk) values
('Mercado abandonado',60,'baixo'),('Hospital',120,'alto'),('Posto de gasolina',90,'medio');

create or replace function public.choose_faction(p_faction_id uuid)
returns void language plpgsql security definer set search_path = public
as $$
declare v_player uuid := auth.uid();
begin
  if v_player is null then raise exception 'Sessão inválida.'; end if;
  if not exists(select 1 from public.factions where id = p_faction_id) then raise exception 'Facção inválida.'; end if;
  update public.profiles set faction_id = p_faction_id
  where id = v_player and faction_id is null;
  if not found then raise exception 'A facção já foi escolhida e não pode ser alterada.'; end if;
  insert into public.inventory(player_id,item_id,quantity)
  select v_player, i.id, v.quantity
  from (values ('Água potável',5),('Comida enlatada',3),('Kit médico',1),('Sucata',2)) as v(item_name,quantity)
  join public.items i on i.name = v.item_name
  on conflict (player_id,item_id) do nothing;
end;
$$;

create or replace function public.start_expedition(p_expedition_type_id uuid)
returns uuid language plpgsql security definer set search_path = public
as $$
declare v_player uuid := auth.uid(); v_id uuid; v_duration integer;
begin
  if v_player is null then raise exception 'Sessão inválida.'; end if;
  if not exists(select 1 from public.profiles where id=v_player and faction_id is not null) then raise exception 'Escolha uma facção primeiro.'; end if;
  select duration_seconds into v_duration from public.expedition_types where id=p_expedition_type_id and active=true;
  if v_duration is null then raise exception 'Expedição indisponível.'; end if;
  insert into public.expeditions(player_id,expedition_type_id,ends_at)
  values(v_player,p_expedition_type_id,now()+make_interval(secs=>v_duration))
  returning id into v_id;
  return v_id;
end;
$$;

create or replace function public.claim_expedition(p_expedition_id uuid)
returns void language plpgsql security definer set search_path = public
as $$
declare v_player uuid := auth.uid(); v_exp public.expeditions%rowtype; v_roll integer; v_item uuid; v_qty integer;
begin
  select * into v_exp from public.expeditions
  where id=p_expedition_id and player_id=v_player for update;
  if not found or v_exp.status <> 'in_progress' then raise exception 'Expedição inválida.'; end if;
  if now() < v_exp.ends_at then raise exception 'O tempo da expedição ainda não terminou.'; end if;
  update public.expeditions set status='claimed' where id=v_exp.id;
  for v_item, v_qty in
    select id, (floor(random()*3)+1)::integer from public.items order by random() limit 2
  loop
    insert into public.inventory(player_id,item_id,quantity) values(v_player,v_item,v_qty)
    on conflict(player_id,item_id) do update set quantity=inventory.quantity+excluded.quantity;
  end loop;
  update public.profiles set reputation=reputation+10 where id=v_player;
end;
$$;



create or replace function public.reward_shelter_author()
returns trigger language plpgsql security definer set search_path = public
as $$
begin
  update public.profiles set reputation = reputation + 15 where id = new.author_id;
  return new;
end;
$$;

drop trigger if exists shelter_created_reward on public.shelters;
create trigger shelter_created_reward
after insert on public.shelters
for each row execute function public.reward_shelter_author();

create or replace function public.set_my_avatar_url(p_avatar_url text)
returns void language plpgsql security definer set search_path = public
as $$
begin
  if auth.uid() is null then raise exception 'Sessão inválida.'; end if;
  if p_avatar_url is null or length(p_avatar_url) > 2048 then raise exception 'URL de avatar inválida.'; end if;
  update public.profiles set avatar_url = p_avatar_url where id = auth.uid();
end;
$$;
grant execute on function public.set_my_avatar_url(text) to authenticated;

alter table public.factions enable row level security;
alter table public.profiles enable row level security;
alter table public.items enable row level security;
alter table public.inventory enable row level security;
alter table public.expedition_types enable row level security;
alter table public.expeditions enable row level security;
alter table public.shelters enable row level security;
alter table public.trades enable row level security;
alter table public.trade_items enable row level security;
alter table public.horde_alerts enable row level security;
alter table public.alert_confirmations enable row level security;

create policy "factions visible to authenticated" on public.factions for select to authenticated using (true);
create policy "profiles readable to authenticated" on public.profiles for select to authenticated using (true);
-- Atualizações sensíveis de perfil devem ser adicionadas por RPCs específicas.
create policy "items visible to authenticated" on public.items for select to authenticated using (true);
create policy "players read own inventory" on public.inventory for select to authenticated using (player_id=auth.uid());
create policy "expedition types visible" on public.expedition_types for select to authenticated using (true);
create policy "players read own expeditions" on public.expeditions for select to authenticated using (player_id=auth.uid());
create policy "shelters visible by policy" on public.shelters for select to authenticated using (visibility='public' or author_id=auth.uid() or faction_id=(select faction_id from public.profiles where id=auth.uid()));
create policy "players insert own shelters" on public.shelters for insert to authenticated with check (author_id=auth.uid());
create policy "authors update shelters" on public.shelters for update to authenticated using (author_id=auth.uid()) with check (author_id=auth.uid());
create policy "authors delete shelters" on public.shelters for delete to authenticated using (author_id=auth.uid());
create policy "trade participants read" on public.trades for select to authenticated using (author_id=auth.uid() or recipient_id=auth.uid());
create policy "trade authors create" on public.trades for insert to authenticated with check (author_id=auth.uid() and author_id<>recipient_id);
create policy "trade participants read items" on public.trade_items for select to authenticated using (exists(select 1 from public.trades t where t.id=trade_id and (t.author_id=auth.uid() or t.recipient_id=auth.uid())));
create policy "active alerts readable" on public.horde_alerts for select to authenticated using (expires_at>now());
create policy "players create own alerts" on public.horde_alerts for insert to authenticated with check (author_id=auth.uid());
create policy "confirmations readable" on public.alert_confirmations for select to authenticated using (true);

grant execute on function public.choose_faction(uuid) to authenticated;
grant execute on function public.start_expedition(uuid) to authenticated;
grant execute on function public.claim_expedition(uuid) to authenticated;

