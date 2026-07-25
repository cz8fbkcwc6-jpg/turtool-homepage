-- Run in Supabase SQL editor (once).
-- Anon can INSERT pre_signups but UPDATE is blocked by RLS, so step2
-- must go through a SECURITY DEFINER RPC.

CREATE OR REPLACE FUNCTION public.complete_pre_signup(
  p_id uuid,
  p_hostel_name text,
  p_region text,
  p_room_count text,
  p_current_method text,
  p_current_method_etc text DEFAULT NULL,
  p_expected_feature text DEFAULT NULL,
  p_resident_app_expectation text DEFAULT NULL,
  p_pain_point text DEFAULT NULL,
  p_cash_receipt_method text DEFAULT NULL
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_id uuid;
BEGIN
  UPDATE public.pre_signups
  SET
    hostel_name = p_hostel_name,
    region = p_region,
    room_count = p_room_count,
    current_method = p_current_method,
    current_method_etc = p_current_method_etc,
    expected_feature = p_expected_feature,
    resident_app_expectation = p_resident_app_expectation,
    pain_point = p_pain_point,
    cash_receipt_method = p_cash_receipt_method,
    step2_completed = true,
    step2_at = now()
  WHERE id = p_id
    AND COALESCE(step2_completed, false) = false
  RETURNING id INTO v_id;

  IF v_id IS NULL THEN
    RETURN jsonb_build_object('ok', false, 'error', 'not_found_or_already_completed');
  END IF;

  RETURN jsonb_build_object('ok', true, 'id', v_id);
END;
$$;

REVOKE ALL ON FUNCTION public.complete_pre_signup(
  uuid, text, text, text, text, text, text, text, text, text
) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.complete_pre_signup(
  uuid, text, text, text, text, text, text, text, text, text
) TO anon, authenticated;
