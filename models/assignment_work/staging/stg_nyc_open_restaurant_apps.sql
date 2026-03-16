-- Clean and standardize NYC open restaurant applications data
-- One row per restaurant application

WITH source AS (
    SELECT *
    FROM {{ source('raw', 'source_nyc_open_restaurant_apps') }}
),

cleaned AS (
    SELECT
        -- Identifiers
        CAST(objectid AS STRING) AS application_id,
        CAST(globalid AS STRING) AS global_id,

        -- Restaurant/business info
        CAST(restaurant_name AS STRING) AS restaurant_name,
        CAST(legal_business_name AS STRING) AS legal_business_name,
        CAST(doing_business_as_dba AS STRING) AS doing_business_as_dba,
        CAST(food_service_establishment AS STRING) AS food_service_establishment,

        -- Address/location
        CAST(bulding_number AS STRING) AS building_number,
        CAST(street AS STRING) AS street,

        CASE
            WHEN UPPER(TRIM(borough)) IN ('MANHATTAN', 'NEW YORK COUNTY') THEN 'Manhattan'
            WHEN UPPER(TRIM(borough)) IN ('BRONX', 'THE BRONX') THEN 'Bronx'
            WHEN UPPER(TRIM(borough)) IN ('BROOKLYN', 'KINGS COUNTY') THEN 'Brooklyn'
            WHEN UPPER(TRIM(borough)) IN ('QUEENS', 'QUEEN', 'QUEENS COUNTY') THEN 'Queens'
            WHEN UPPER(TRIM(borough)) IN ('STATEN ISLAND', 'RICHMOND COUNTY') THEN 'Staten Island'
            ELSE 'UNKNOWN'
        END AS borough,

        CASE
            WHEN UPPER(TRIM(CAST(zip AS STRING))) IN ('N/A', 'NA', '') THEN NULL
            WHEN REGEXP_CONTAINS(TRIM(CAST(zip AS STRING)), r'^\d{5}$') THEN TRIM(CAST(zip AS STRING))
            WHEN REGEXP_CONTAINS(TRIM(CAST(zip AS STRING)), r'^\d{5}-\d{4}$') THEN TRIM(CAST(zip AS STRING))
            WHEN REGEXP_CONTAINS(TRIM(CAST(zip AS STRING)), r'^\d{9}$') THEN TRIM(CAST(zip AS STRING))
            ELSE NULL
        END AS zip_code,

        CAST(business_address AS STRING) AS business_address,

        -- Seating/application info
        CAST(seating_interest_sidewalk AS STRING) AS seating_interest_sidewalk,

        CASE
            WHEN UPPER(TRIM(CAST(approved_for_sidewalk_seating AS STRING))) IN ('YES', 'Y', 'TRUE') THEN TRUE
            WHEN UPPER(TRIM(CAST(approved_for_sidewalk_seating AS STRING))) IN ('NO', 'N', 'FALSE') THEN FALSE
            ELSE NULL
        END AS approved_for_sidewalk_seating,

        CASE
            WHEN UPPER(TRIM(CAST(approved_for_roadway_seating AS STRING))) IN ('YES', 'Y', 'TRUE') THEN TRUE
            WHEN UPPER(TRIM(CAST(approved_for_roadway_seating AS STRING))) IN ('NO', 'N', 'FALSE') THEN FALSE
            ELSE NULL
        END AS approved_for_roadway_seating,

        CASE
            WHEN UPPER(TRIM(CAST(qualify_alcohol AS STRING))) IN ('YES', 'Y', 'TRUE') THEN TRUE
            WHEN UPPER(TRIM(CAST(qualify_alcohol AS STRING))) IN ('NO', 'N', 'FALSE') THEN FALSE
            ELSE NULL
        END AS qualify_alcohol,

        CAST(sla_serial_number AS STRING) AS sla_serial_number,
        CAST(sla_license_type AS STRING) AS sla_license_type,
        CAST(landmark_district_or_building AS STRING) AS landmark_district_or_building,
        CAST(landmarkdistrict_terms AS STRING) AS landmarkdistrict_terms,
        CAST(healthcompliance_terms AS STRING) AS healthcompliance_terms,

        -- Timing
        CAST(time_of_submission AS TIMESTAMP) AS time_of_submission,

        -- Coordinates / geography
        CAST(latitude AS NUMERIC) AS latitude,
        CAST(longitude AS NUMERIC) AS longitude,
        CAST(community_board AS STRING) AS community_board,
        CAST(council_district AS STRING) AS council_district,
        CAST(census_tract AS STRING) AS census_tract,
        CAST(bin AS STRING) AS bin,
        CAST(bbl AS STRING) AS bbl,
        CAST(nta AS STRING) AS nta,

        -- Dimensions
        CAST(sidewalk_dimensions_length AS NUMERIC) AS sidewalk_dimensions_length,
        CAST(sidewalk_dimensions_width AS NUMERIC) AS sidewalk_dimensions_width,
        CAST(sidewalk_dimensions_area AS NUMERIC) AS sidewalk_dimensions_area,
        CAST(roadway_dimensions_length AS NUMERIC) AS roadway_dimensions_length,
        CAST(roadway_dimensions_width AS NUMERIC) AS roadway_dimensions_width,
        CAST(roadway_dimensions_area AS NUMERIC) AS roadway_dimensions_area,

        -- Metadata
        CURRENT_TIMESTAMP() AS _stg_loaded_at

    FROM source
    WHERE objectid IS NOT NULL
      AND borough IS NOT NULL
      AND time_of_submission IS NOT NULL

    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY objectid
        ORDER BY time_of_submission DESC
    ) = 1
)

SELECT *
FROM cleaned