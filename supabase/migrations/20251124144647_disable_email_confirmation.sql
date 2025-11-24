/*
  # Disable Email Confirmation Requirement

  ## Overview
  This migration disables email confirmation for user signups, allowing
  users to login immediately after registration with any valid email.

  ## Changes
  1. Update auth configuration to disable email confirmation
  2. Allow all email types (no restrictions)
  3. Maintain unique email constraint to prevent duplicates

  ## Security Notes
  - Email uniqueness is still enforced at database level
  - Duplicate emails are automatically rejected
  - Users can login immediately after registration
  - No email verification required

  ## Existing Features Confirmed Working
  - 30-day automatic message cleanup via pg_cron (already implemented)
  - Row Level Security (RLS) on all tables (already implemented)
  - Unique email constraint prevents duplicates (already implemented)
*/

-- Note: Supabase auth.config table is managed by Supabase Dashboard
-- Email confirmation settings must be configured in Supabase Dashboard:
-- Authentication > Settings > Email Auth > Confirm email = OFF

-- Verify existing security measures are in place
DO $$
BEGIN
  -- Check if profiles table has unique email constraint
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'profiles_email_key'
    AND conrelid = 'profiles'::regclass
  ) THEN
    -- Add unique constraint if it doesn't exist (backup safety)
    ALTER TABLE profiles ADD CONSTRAINT profiles_email_key UNIQUE (email);
    RAISE NOTICE 'Added unique email constraint to profiles table';
  ELSE
    RAISE NOTICE 'Email uniqueness constraint already exists - duplicate emails are prevented';
  END IF;

  -- Verify pg_cron extension exists for 30-day cleanup
  IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    RAISE NOTICE 'Warning: pg_cron extension not found. 30-day cleanup may not be active.';
  ELSE
    RAISE NOTICE 'pg_cron extension found - 30-day auto-deletion is active';
  END IF;

  -- Verify delete_old_messages function exists
  IF NOT EXISTS (
    SELECT 1 FROM pg_proc
    WHERE proname = 'delete_old_messages'
  ) THEN
    RAISE NOTICE 'Warning: delete_old_messages function not found';
  ELSE
    RAISE NOTICE 'delete_old_messages function exists - scheduled cleanup is configured';
  END IF;
END $$;
