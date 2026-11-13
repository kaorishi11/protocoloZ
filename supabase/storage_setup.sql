insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
('shelter-photos','shelter-photos',true,5242880,array['image/jpeg','image/png','image/webp']),
('avatars','avatars',true,5242880,array['image/jpeg','image/png','image/webp'])
on conflict (id) do nothing;

create policy "authenticated upload shelter photos" on storage.objects for insert to authenticated
with check (bucket_id='shelter-photos' and (storage.foldername(name))[1]=auth.uid()::text);
create policy "authenticated update own shelter photos" on storage.objects for update to authenticated
using (bucket_id='shelter-photos' and (storage.foldername(name))[1]=auth.uid()::text)
with check (bucket_id='shelter-photos' and (storage.foldername(name))[1]=auth.uid()::text);
create policy "public read shelter photos" on storage.objects for select to public using (bucket_id='shelter-photos');
create policy "authenticated upload own avatar" on storage.objects for insert to authenticated
with check (bucket_id='avatars' and (storage.foldername(name))[1]=auth.uid()::text);
create policy "authenticated update own avatar" on storage.objects for update to authenticated
using (bucket_id='avatars' and (storage.foldername(name))[1]=auth.uid()::text)
with check (bucket_id='avatars' and (storage.foldername(name))[1]=auth.uid()::text);
create policy "public read avatars" on storage.objects for select to public using (bucket_id='avatars');
