CREATE TABLE public.model_unlocks (
  user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT ON public.model_unlocks TO authenticated;
GRANT ALL ON public.model_unlocks TO service_role;
ALTER TABLE public.model_unlocks ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users see own unlock" ON public.model_unlocks FOR SELECT TO authenticated USING (auth.uid() = user_id);

CREATE TABLE public.projects (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name text NOT NULL DEFAULT 'Untitled app',
  kind text NOT NULL DEFAULT 'web',
  files jsonb NOT NULL DEFAULT '{}'::jsonb,
  messages jsonb NOT NULL DEFAULT '[]'::jsonb,
  slug text UNIQUE,
  published boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT, INSERT, UPDATE, DELETE ON public.projects TO authenticated;
GRANT SELECT ON public.projects TO anon;
GRANT ALL ON public.projects TO service_role;
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Owners manage projects" ON public.projects FOR ALL TO authenticated USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Anyone can view published projects" ON public.projects FOR SELECT TO anon, authenticated USING (published = true);
CREATE INDEX projects_user_idx ON public.projects(user_id, updated_at DESC);