fvsne_plots_filter <- function(.data) {
  # FIA.PLOTGEOM.FVS_VARIANT tells which FVS variant to use for a given plot.
  .data |> filter(FVS_VARIANT == 'NE')
}

ners_plots_filter <- function(.data) {
  # FIA.SURVEY.RCSD tells which research station administers a plot.
  .data |> filter(RSCD == 24)
}

modern_plots_filter <- function(.data) {
  # FIADB database description Appendix G describes plot designs.
  # DESIGNCD 1 is the modern plot design.
  # Many other plot designs are compatible with DESIGNCD == 1
  #.data |> filter(
  #  (DESIGNCD == 1) |
  #  (DESIGNCD > 100 & DESIGNCD < 200) |
  #  (DESIGNCD >= 220 & DESIGNCD < 299) |
  #  (DESIGNCD > 300 & DESIGNCD < 325) |
  #  (DESIGNCD == 328) |
  #  (DESIGNCD > 500 & DESIGNCD < 550) |
  #  (DESIGNCD == 553) |
  #  (DESIGNCD == 554) |
  #  (DESIGNCD > 600 & DESIGNCD < 700)
  #)
  # ---
  # If the plot was part of the 2005 or later inventories, it's modern.
  .data |>
    group_by(STATECD, COUNTYCD, PLOT) |>
    filter(max(INVYR, na.rm = TRUE) >= 2005) |>
    ungroup()
}

long_measurement_filter <- function(.data) {
  # Only retain plots that have measurements a long time apart
  .data |>
    group_by(STATECD, COUNTYCD, PLOT) |>
    filter((max(MEASYEAR, na.rm = TRUE) - min(MEASYEAR, na.rm = TRUE)) >= 10) |>
    ungroup()
}

forested_plots_filter <- function(.data) {
  # Condition status is forested
  # Filter out the entire plot if any condition was not forested for
  # any part of the period
  .data |>
    group_by(STATECD, COUNTYCD, PLOT) |>
    filter(max(COND_STATUS_CD, na.rm = TRUE) == 1) |>
    ungroup()
}

undisturbed_plots_filter <- function(.data) {
  # Filter out the entire plot if it was disturbed in any year
  .data |>
    group_by(STATECD, COUNTYCD, PLOT) |>
    filter(
      (is.na(max(DSTRBCD1, na.rm = TRUE)) | max(DSTRBCD1, na.rm = TRUE) == 0) & 
        (is.na(max(DSTRBCD2, na.rm = TRUE)) | max(DSTRBCD2, na.rm = TRUE) == 0) &
        (is.na(max(DSTRBCD3, na.rm = TRUE)) | max(DSTRBCD3, na.rm = TRUE) == 0)
    ) |>
    ungroup()
}

untreated_plots_filter <- function(.data) {
  # Filter out the entire plot if it was treated in any year
  .data |>
    group_by(STATECD, COUNTYCD, PLOT) |>
    filter(
      (is.na(max(TRTCD1, na.rm = TRUE)) | max(TRTCD1, na.rm = TRUE) == 0) &
        (is.na(max(TRTCD2, na.rm = TRUE)) | max(TRTCD2, na.rm = TRUE) == 0) &
        (is.na(max(TRTCD3, na.rm = TRUE)) | max(TRTCD3, na.rm = TRUE) == 0)
    ) |>
    ungroup()
}

harvested_plots_filter <- function(.data) {
  # Filter out the entire plot if no trees were cut
  .data |>
    group_by(STATECD, COUNTYCD, PLOT) |>
    filter(
      sum(
        if_else(!is.na(TRTCD1) & TRTCD1 == 10, 1,
          if_else(!is.na(TRTCD2) & TRTCD2 == 10, 1,
            if_else(!is.na(TRTCD3) & TRTCD3 == 10, 1, 0)
          )
        ),
        na.rm = TRUE
      ) > 0
    ) |>
    ungroup()
}

no_unnatural_regen_filter <- function(.data) {
  # Filter out the entire plot if it was treated to encourage growth
  # TRTCD 30 - Artificial regeneration - planting or direct seeding
  # TRTCD 50 - Other silvicultural treatment - fertilizers, herbicides, etc.
  .data |> 
    group_by(STATECD, COUNTYCD, PLOT) |> 
    filter(
      sum(
        if_else(!is.na(TRTCD1) & TRTCD1 == 30, 1,
          if_else(!is.na(TRTCD2) & TRTCD2 == 30, 1,
            if_else(!is.na(TRTCD3) & TRTCD3 == 30, 1, 0)
          )
        ),
        na.rm = TRUE
      ) == 0
    ) |>
    filter(
      sum(
        if_else(!is.na(TRTCD1) & TRTCD1 == 50, 1,
          if_else(!is.na(TRTCD2) & TRTCD2 == 50, 1,
            if_else(!is.na(TRTCD3) & TRTCD3 == 50, 1, 0)
          )
        ),
        na.rm = TRUE
      ) == 0
    ) |>
    ungroup()
}

measured_pre_post_harvest_filter <- function(.data) {
  # Remove the entire plot if:
  # 1. The plot was not measured prior to the earliest harvest in the window,
  # and
  # 2. The plot was not measured 10 years after the most recent harvest.
  # Note that a single condition can have multiple harvest years,
  # meaning more than one of TRTCD1, TRTCD2 and TRTCD3 is 10, and
  # TRTYR1, TRTYR2 and TRTYR3 are different.
  # We want the latest of the latest harvests.
  .data |> 
    group_by(STATECD, COUNTYCD, PLOT) |>
    mutate(
      MIN_MEASYEAR = min(MEASYEAR, na.rm = TRUE),
      MAX_MEASYEAR = max(MEASYEAR, na.rm = TRUE),
      MIN_HRVYR1 = min(if_else(!is.na(TRTCD1) & (TRTCD1 == 10), TRTYR1, 9999), na.rm = TRUE),
      MAX_HRVYR1 = max(if_else(!is.na(TRTCD1) & (TRTCD1 == 10), TRTYR1, 0), na.rm = TRUE),
      MIN_HRVYR2 = min(if_else(!is.na(TRTCD2) & (TRTCD2 == 10), TRTYR2, 9999), na.rm = TRUE),
      MAX_HRVYR2 = max(if_else(!is.na(TRTCD2) & (TRTCD2 == 10), TRTYR2, 0), na.rm = TRUE),
      MIN_HRVYR3 = min(if_else(!is.na(TRTCD3) & (TRTCD3 == 10), TRTYR3, 9999), na.rm = TRUE),
      MAX_HRVYR3 = max(if_else(!is.na(TRTCD3) & (TRTCD3 == 10), TRTYR3, 0), na.rm = TRUE),
      MIN_HRVYR =
        if_else(
          MIN_HRVYR1 < MIN_HRVYR2,
          if_else(
            MIN_HRVYR1 < MIN_HRVYR3,
            MIN_HRVYR1,
            MIN_HRVYR3
          ),
          if_else(
            MIN_HRVYR2 < MIN_HRVYR3,
            MIN_HRVYR2,
            MIN_HRVYR3
          )
        ),
      MAX_HRVYR =
        if_else(
          MAX_HRVYR1 > MAX_HRVYR2,
          if_else(
            MAX_HRVYR1 > MAX_HRVYR3,
            MAX_HRVYR1,
            MAX_HRVYR3
          ),
          if_else(
            MAX_HRVYR2 > MAX_HRVYR3,
            MAX_HRVYR2,
            MAX_HRVYR3
          )
        )
    ) |> 
    filter(
      (MIN_MEASYEAR < MIN_HRVYR) &
      (MAX_MEASYEAR - MAX_HRVYR >= 10)
    ) |> 
    ungroup()
}

single_condition_plots_filter <- function(.data) {
  # Filter out the entire plot if it ever had more than one condition
  .data |>
    group_by(STATECD, COUNTYCD, PLOT) |>
    filter(max(CONDID, na.rm = TRUE) == 1) |>
    ungroup()
}

has_trees_filter <- function(.data) {
  .data |>
    # Filter out inventory years with no BALIVE
    group_by(STATECD, COUNTYCD, PLOT, INVYR) |>
    filter(
      sum(if_else(is.na(BALIVE), 0, BALIVE), na.rm = TRUE) > 0
    ) |>
    ungroup()
}

ingrowth_filter <- function(.data) {
  .data |>
    # From TREE_GRM_COMPONENT, filter to records marked ingrowth
    filter(
      MICR_COMPONENT_AL_FOREST == 'INGROWTH' |
      SUBP_COMPONENT_AL_FOREST == 'INGROWTH'
    )
}

consolidate_forest_type_groups_filter <- function(.data) {
  # Consolidate a few rare forest type groups into a single 'Other' group:
  # Exotic hardwoods group
  # Exotic softwoods group
  # Other eastern softwoods group
  # Other hardwoods group
  .data |>
    mutate(`Forest Type Group` = 
     if_else(startsWith(`Forest Type Group`, 'Other'), 'Other',
       if_else(startsWith(`Forest Type Group`, 'Exotic'), 'Other',
         `Forest Type Group`
       )
     )
    )
}

large_end_diameter_class_filter <- function(.data) {
  .data |>
    mutate(
      LARGE_END_DIA_CLASS = case_when(
        DIA < 3 ~ "0.0 - 2.9",
        DIA < 5 ~ "3.0 - 4.9",
        DIA < 9 ~ "5.0 - 8.9",
        DIA < 15 ~ "9.0 - 14.9",
        DIA < 21 ~ "15.0 - 20.9",
        DIA < 40 ~ "21.0 - 39.9",
        .default = "40.0 +"
      )
    )
}

decode_cclcd_filter <- function(.data) {
  .data |>
    mutate(
      CCL = case_when(
        CCLCD == 1 ~"Open grown",
        CCLCD == 2 ~"Dominant",
        CCLCD == 3 ~"Codominant",
        CCLCD == 4 ~"Intermediate",
        CCLCD == 5 ~"Overtopped"
      )
    )
}

hectare_at <- function(lat, lon) {
  old_axis_order <- st_axis_order()
  st_axis_order(TRUE)
  
  crs <- 'EPSG:4326'
  center <- c(lat, lon)
  center_point <- st_point(center)
  # 0.001 degrees is about 111.17 meters at the equator, so start with half of that
  approx_offset <- 0.001 / 2
  a <- st_sfc(center_point + c( approx_offset, 0), crs = crs)
  b <- st_sfc(center_point + c(-approx_offset, 0), crs = crs)
  # The result is the distance between a and b is in meters per 0.001 degree;
  # invert and multiply by 50 to get degrees per 50 meters
  fifty_meter_angle_lat <- 0.05 / as.numeric(st_distance(a, b))
  
  c <- st_sfc(center_point + c(0,  approx_offset), crs = crs)
  d <- st_sfc(center_point + c(0, -approx_offset), crs = crs)
  fifty_meter_angle_lon <- 0.05 / as.numeric(st_distance(c, d))
  
  south_west <- c(-fifty_meter_angle_lat, -fifty_meter_angle_lon)
  north_west <- c( fifty_meter_angle_lat, -fifty_meter_angle_lon)
  north_east <- c( fifty_meter_angle_lat,  fifty_meter_angle_lon)
  south_east <- c(-fifty_meter_angle_lat,  fifty_meter_angle_lon)
  
  # Note: winding direction matters!
  hectare_geometry = matrix(
    c(
      center + north_west,
      center + south_west,
      center + south_east,
      center + north_east,
      center + north_west
    ),
    ncol = 2,
    byrow = TRUE
  )
  hectare_polygon <- st_sfc(st_polygon(list(hectare_geometry)), crs = crs)
  st_axis_order(old_axis_order)
  hectare_polygon
}

fvs_kwd0 <- function(kwd) {
  sprintf('%-10s', kwd)
}

fvs_kwd1 <- function(kwd, arg1) {
  arg1 <- as.character(arg1)
  sprintf('%-10s%10s', kwd, arg1)
}

fvs_kwd2 <- function(kwd, arg1, arg2) {
  arg1 <- as.character(arg1)
  arg2 <- as.character(arg2)
  sprintf('%-10s%10s%10s', kwd, arg1, arg2)
}

fvs_kwd3 <- function(kwd, arg1, arg2, arg3) {
  arg1 <- as.character(arg1)
  arg2 <- as.character(arg2)
  arg3 <- as.character(arg3)
  sprintf('%-10s%10s%10s%10s', kwd, arg1, arg2, arg3)
}

fvs_kwd4 <- function(kwd, arg1, arg2, arg3, arg4) {
  arg1 <- as.character(arg1)
  arg2 <- as.character(arg2)
  arg3 <- as.character(arg3)
  arg4 <- as.character(arg4)
  sprintf('%-10s%10s%10s%10s%10s', kwd, arg1, arg2, arg3, arg4)
}

fvs_kwd5 <- function(kwd, arg1, arg2, arg3, arg4, arg5) {
  arg1 <- as.character(arg1)
  arg2 <- as.character(arg2)
  arg3 <- as.character(arg3)
  arg4 <- as.character(arg4)
  arg5 <- as.character(arg5)
  sprintf('%-10s%10s%10s%10s%10s%10s', kwd, arg1, arg2, arg3, arg4, arg5)
}

fvs_kwd6 <- function(kwd, arg1, arg2, arg3, arg4, arg5, arg6) {
  arg1 <- as.character(arg1)
  arg2 <- as.character(arg2)
  arg3 <- as.character(arg3)
  arg4 <- as.character(arg4)
  arg5 <- as.character(arg5)
  arg6 <- as.character(arg6)
  sprintf('%-10s%10s%10s%10s%10s%10s%10s', kwd, arg1, arg2, arg3, arg4, arg5, arg6)
}

fvs_kwd7 <- function(kwd, arg1, arg2, arg3, arg4, arg5, arg6, arg7) {
  arg1 <- as.character(arg1)
  arg2 <- as.character(arg2)
  arg3 <- as.character(arg3)
  arg4 <- as.character(arg4)
  arg5 <- as.character(arg5)
  arg6 <- as.character(arg6)
  arg7 <- as.character(arg7)
  sprintf('%-10s%10s%10s%10s%10s%10s%10s%10s', kwd, arg1, arg2, arg3, arg4, arg5, arg6, arg7)
}

fvs_TimeConfig <- function(FirstYear, LastYear, Timestep) {
  FirstYear <- as.integer(FirstYear)
  LastYear <- as.integer(LastYear)
  Timestep <- as.integer(Timestep)
  TimeConfig <- NULL
  if (FirstYear == LastYear) {
    # Produce a single one-year cycle
    TimeConfig <- c(
      fvs_kwd1("InvYear", FirstYear),
      fvs_kwd2("TimeInt", 0, 1),
      fvs_kwd1("NumCycle", 1)
    )      
  } else {
    # LastYear must be the first year of the last cycle, so
    # add an extra cycle at the end
    NumCycles <- as.integer((LastYear - FirstYear) / Timestep) + 1
    ShortCycle <- (LastYear - FirstYear) %% Timestep
    if (ShortCycle > 0) {
      # Produce a single short cycle followed by 10-year cycles
      NumCycles <- NumCycles + 1
      TimeConfig <- c(
        fvs_kwd1("InvYear", FirstYear),
        fvs_kwd2("TimeInt", 0, Timestep),
        fvs_kwd2("TimeInt", 1, ShortCycle),
        fvs_kwd2("TimeInt", NumCycles, 1),
        fvs_kwd1("NumCycle", NumCycles)
      )
    } else {
      # No need for an initial short cycle
      TimeConfig <- c(
        fvs_kwd1("InvYear", FirstYear),
        fvs_kwd2("TimeInt", 0, Timestep),
        fvs_kwd2("TimeInt", NumCycles, 1),
        fvs_kwd1("NumCycle", NumCycles)
      )
    }
  }
  return(TimeConfig)
}

fvs_Estab <- function(rows) {
  natural_regen <- function(row) {
    year <- 0
    species <- row["species"]
    density <- row["density"] # TPA
    survival <- 100 # percent
    age <- ''
    if ("height" %in% names(row)) {
      height <- row["height"]
    } else {
      height <- ''
    }
    shade <- 0
    fvs_kwd7("Natural", year, species, density, survival, age, height, shade)
  }
  Estab <- c(
    fvs_kwd1("If", 0),
    fvs_kwd0("mod(cycle,1) eq 0"),
    fvs_kwd0("Then"),
    fvs_kwd1("Estab", 0),
    fvs_kwd2("MechPrep", 0, 0),
    fvs_kwd2("BurnPrep", 0, 0),
    fvs_kwd0("Sprout"),
    apply(rows, 1, natural_regen),
    fvs_kwd0("End"),
    fvs_kwd0("EndIf")
  )
  return(Estab)
}
