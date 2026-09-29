CREATE TABLE public.subscriptions (
  user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  tier text NOT NULL DEFAULT 'free' CHECK (tier IN ('free','basic','pro','ultimate')),
  status text NOT NULL DEFAULT 'active',
  current_period_end timestamptz,
  provider_subscription_id text,
  updated_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT ON public.subscriptions TO authenticated;
GRANT ALL ON public.subscriptions TO service_role;
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users view own subscription" ON public.subscriptions FOR SELECT TO authenticated USING (auth.uid() = user_id);

CREATE TABLE public.token_usage (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  tokens integer NOT NULL CHECK (tokens >= 0),
  model text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);
GRANT SELECT ON public.token_usage TO authenticated;
GRANT ALL ON public.token_usage TO service_role;
ALTER TABLE public.token_usage ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users view own usage" ON public.token_usage FOR SELECT TO authenticated USING (auth.uid() = user_id);
CREATE INDEX token_usage_user_time ON public.token_usage (user_id, created_at DESC);

CREATE OR REPLACE FUNCTION public.usage_by_day(_since timestamptz)
RETURNS TABLE(day date, tokens bigint)
LANGUAGE sql STABLE SECURITY INVOKER SET search_path = public AS $$
  SELECT (created_at AT TIME ZONE 'UTC')::date AS day, SUM(tokens)::bigint
  FROM public.token_usage
  WHERE user_id = auth.uid() AND created_at >= _since
  GROUP BY 1 ORDER BY 1
$$;
GRANT EXECUTE ON FUNCTION public.usage_by_day(timestamptz) TO authenticated;