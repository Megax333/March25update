-- Create audio_rooms table
CREATE TABLE IF NOT EXISTS public.audio_rooms (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    host_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL
);

-- Create audio_room_participants table to track who is in which room
CREATE TABLE IF NOT EXISTS public.audio_room_participants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    room_id UUID NOT NULL REFERENCES public.audio_rooms(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT now() NOT NULL,
    UNIQUE(room_id, user_id)
);

-- Create RLS policies for audio_rooms
ALTER TABLE public.audio_rooms ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view audio rooms"
    ON public.audio_rooms
    FOR SELECT
    USING (true);

CREATE POLICY "Authenticated users can create audio rooms"
    ON public.audio_rooms
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = host_id);

CREATE POLICY "Room hosts can update their rooms"
    ON public.audio_rooms
    FOR UPDATE
    TO authenticated
    USING (auth.uid() = host_id)
    WITH CHECK (auth.uid() = host_id);

CREATE POLICY "Room hosts can delete their rooms"
    ON public.audio_rooms
    FOR DELETE
    TO authenticated
    USING (auth.uid() = host_id);

-- Create RLS policies for audio_room_participants
ALTER TABLE public.audio_room_participants ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view room participants"
    ON public.audio_room_participants
    FOR SELECT
    USING (true);

CREATE POLICY "Authenticated users can join rooms"
    ON public.audio_room_participants
    FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can leave rooms"
    ON public.audio_room_participants
    FOR DELETE
    TO authenticated
    USING (auth.uid() = user_id);

-- Create function to get room participants
CREATE OR REPLACE FUNCTION public.get_room_participants(room_id UUID)
RETURNS TABLE (
    user_id UUID,
    username TEXT,
    avatar_url TEXT
)
LANGUAGE SQL
SECURITY DEFINER
AS $$
    SELECT
        p.user_id,
        profiles.username,
        profiles.avatar_url
    FROM
        public.audio_room_participants p
    JOIN
        public.profiles ON p.user_id = profiles.id
    WHERE
        p.room_id = room_id;
$$;

-- Add updated_at trigger for audio_rooms
CREATE TRIGGER set_updated_at_timestamp
BEFORE UPDATE ON public.audio_rooms
FOR EACH ROW
EXECUTE FUNCTION public.set_updated_at_timestamp();
