-- Extensions and initial setup
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Counties
CREATE TABLE IF NOT EXISTS counties (
county_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
name TEXT NOT NULL,
state TEXT NOT NULL,
fips TEXT,
portal_url TEXT,
created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Properties / parcel
CREATE TABLE IF NOT EXISTS properties (
property_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
county_id UUID REFERENCES counties(county_id) ON DELETE SET NULL,
parcel_id TEXT,
address_normalized TEXT,
street_number TEXT,
street_name TEXT,
city TEXT,
state TEXT,
zip TEXT,
lat DOUBLE PRECISION,
lon DOUBLE PRECISION,
geom geometry(Point, 4326),
last_sale_date DATE,
last_sale_amount BIGINT,
acres DOUBLE PRECISION,
bldg_sqft INTEGER,
year_built INTEGER,
is_vacant BOOLEAN DEFAULT NULL,
created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_properties_parcel ON properties(parcel_id);
CREATE INDEX IF NOT EXISTS idx_properties_geom ON properties USING GIST(geom);

-- Owners (persons or entities)
CREATE TABLE IF NOT EXISTS owners (
owner_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
name_full TEXT,
name_first TEXT,
name_last TEXT,
is_entity BOOLEAN DEFAULT FALSE,
addresses JSONB,
created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- owner-property relationship (ownership history)
CREATE TABLE IF NOT EXISTS owner_property (
id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
owner_id UUID REFERENCES owners(owner_id) ON DELETE CASCADE,
property_id UUID REFERENCES properties(property_id) ON DELETE CASCADE,
ownership_type TEXT,
start_date DATE,
end_date DATE,
source TEXT,
created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Mortgages / loans
CREATE TABLE IF NOT EXISTS mortgages (
mortgage_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
property_id UUID REFERENCES properties(property_id),
owner_id UUID REFERENCES owners(owner_id),
orig_lender TEXT,
current_servicer TEXT,
loan_amount NUMERIC,
orig_date DATE,
maturity_date DATE,
loan_type TEXT,
loan_status TEXT,
last_update TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Events (lis pendens, trustee sale, tax lien, bankruptcy, eviction)
CREATE TABLE IF NOT EXISTS events (
event_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
property_id UUID REFERENCES properties(property_id),
owner_id UUID REFERENCES owners(owner_id),
county_id UUID REFERENCES counties(county_id),
event_type TEXT NOT NULL,
event_date DATE,
doc_number TEXT,
doc_url TEXT,
source TEXT,
raw_payload JSONB,
parsed_text TEXT,
created_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_events_property ON events(property_id);
CREATE INDEX IF NOT EXISTS idx_events_type_date ON events(event_type, event_date);

-- Documents (raw files)
CREATE TABLE IF NOT EXISTS documents (
document_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
event_id UUID REFERENCES events(event_id),
url TEXT,
local_path TEXT,
mime_type TEXT,
fetched_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Scores
CREATE TABLE IF NOT EXISTS scores (
score_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
property_id UUID REFERENCES properties(property_id),
score FLOAT,
score_model TEXT,
score_date TIMESTAMP WITH TIME ZONE DEFAULT now(),
features_snapshot JSONB
);
CREATE INDEX IF NOT EXISTS idx_scores_property_date ON scores(property_id, score_date);

-- Outreach activities / dispositions
CREATE TABLE IF NOT EXISTS activities (
activity_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
property_id UUID REFERENCES properties(property_id),
owner_id UUID REFERENCES owners(owner_id),
user_id UUID,
activity_type TEXT,
activity_time TIMESTAMP WITH TIME ZONE DEFAULT now(),
notes TEXT,
disposition TEXT,
source TEXT
);

-- Phone/email append cache
CREATE TABLE IF NOT EXISTS contact_append (
id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
owner_id UUID REFERENCES owners(owner_id),
phone TEXT,
phone_confidence FLOAT,
email TEXT,
email_confidence FLOAT,
source TEXT,
last_checked TIMESTAMP WITH TIME ZONE DEFAULT now()
);
