-- Seating type dimension for open restaurant applications

WITH seating_types AS (

    SELECT DISTINCT
        approved_for_sidewalk_seating AS sidewalk_seating,
        approved_for_roadway_seating AS roadway_seating

    FROM {{ ref('stg_nyc_open_restaurant_apps') }}

),

seating_dimension AS (

    SELECT
        {{ dbt_utils.generate_surrogate_key(['sidewalk_seating','roadway_seating']) }} AS seating_type_key,
        sidewalk_seating,
        roadway_seating

    FROM seating_types

)

SELECT * 
FROM seating_dimension