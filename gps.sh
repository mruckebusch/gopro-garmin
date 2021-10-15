#!/usr/bin/env bash

# converts a FIT log file into a CSV file
# COLNUM COLNAME                  EXAMPLE VALUE           COMMENT
# 01 timestamp[s]                 "995990727"             USE for filtering
# 02 position_lat[semicircles]    "582881112"             IGNORE
# 03 position_long[semicircles]   "27482251"              IGNORE
# 04 distance[m]                  "11.83"                 USE
# 05 altitude[m]                  "182.39999999999998"    USE (grade %)
# 06 speed[m/s]                   "4.031"                 USE
# 07 unknown                                              IGNORE
# 08 heart_rate[bpm]              "102"                   USE
# 09 cadence[rpm]                 "54"                    USE
# 10 temperature[C]               "30"                    IGNORE
# 11 fractional_cadence[rpm]      "0.0"                   IGNORE
# 12 enhanced_altitude[m]         "182.39999999999998"    IGNORE
# 13 enhanced_speed[m/s]          "4.031"                 IGNORE
#
# $1 the input FIT file path
# $2 the output file path without suffix
#Output STDOUT: the output file path, ending with suffix "_data.csv"
function __fit_to_csv {
    local fit_file
    fit_file="$1"
    local csv_file
    csv_file="$2"

    java -jar "${GARMIN_FITCSVTOOL_JAR}" -b "${fit_file}" \
        "${csv_file}" --defn "none" --data "record" 1> "/dev/null"
    #I don't need this "dirty" file automatically generated
    rm "${csv_file}.csv"
    #I do need this one:
    csv_file="${csv_file}_data.csv"
    ___remove_BOM "${csv_file}"
    echo "${csv_file}"
}

#Converts a CSV file into ffmpeg file
# $1 the input concatenated csv file path
# $2 the output ffmpeg command file path
# $3 the elapsed time offset in seconds
function __convert_csv_to_cmd {
    local concatenated_csv_data
    concatenated_csv_data="$1"
    local cmd_file
    cmd_file="$2"
    local elapsed_offset
    elapsed_offset="$3"
    #write at least one line, useful if there is no gps data
    echo "0-0 [leave] drawtext reinit 'text=';" > "${cmd_file}"
    local interval_start
    interval_start=0
    #shellcheck disable=SC2034
    while IFS=, read -r ts dist alt speed cadence hr; do
        printf "%d-%d [enter] drawtext reinit 'text=\\n" \
               "${interval_start}" $((interval_start + 1))

        printf "Elapsed      %02d\\:%02d\\:%02d\\n"                   \
               $(( (interval_start + elapsed_offset) / 3600 ))        \
               $(( ( (interval_start + elapsed_offset) / 60 ) % 60 )) \
               $(( (interval_start + elapsed_offset) % 60 ))
        printf "Cadence      %d RPM\\n" \
               "${cadence}"
        dist=$(bc <<< "scale=2 ; ${dist} / 1000")
        printf "Distance     %0.2f Km\\n"                 \
               "${dist}"

        #TODO add Grade metric (with %unit) based on alt and dist
        printf "Grade         %+.2f (random for now)\\n" \
               $((-10 + RANDOM % 20))
        speed=$(bc <<< "${speed} * 3.6")
        printf "Speed        %0.f KPH\\n" \
               "${speed}"
        printf "Heart rate     %d BPM\\n" \
               "${hr}"
        printf "';\\n"
        interval_start=$((interval_start + 1))

    done < "${concatenated_csv_data}" >> "${cmd_file}"
}


#Converts a list of FIT files into a "concatenated" CSV file
# $1 the day with format yyyy-MM-dd
# $@ all fit files
# outputs to STDOUT the path to clean CSV record file
function _fit_to_csv_records_day {
    local day
    day="$1"
    shift

    #warning: this is an array variable
    declare -a logs_gps_csv_data
    logs_gps_csv_data=()
    #shellcheck disable=SC2068
    for fit_file in $@; do
    local csv_file
    csv_file=$(basename "${fit_file}")
    csv_file="${WORKING_FOLDER}/${csv_file}"

    csv_file=$(__fit_to_csv "${fit_file}" "${csv_file}")

    local namedcol
    namedcol='record.timestamp[s]'
    namedcol+=',record.distance[m]'
    namedcol+=',record.altitude[m]'
    namedcol+=',record.speed[m/s]'
    namedcol+=',record.cadence[rpm]'
    #add column 'record.heart_rate[bpm]' only if available
    if grep --quiet 'record.heart_rate' "${csv_file}" ; then
        namedcol+=',record.heart_rate[bpm]'
    fi


    csvtool namedcol "${namedcol}" "${csv_file}" \
        > "${csv_file}_interesting_cols"

    csv_file="${csv_file}_interesting_cols"
        __remove_header "${csv_file}"
        csv_file="${csv_file}_noheader"
    logs_gps_csv_data+=("${csv_file}")
    done

    local concatenated_csv_data
    concatenated_csv_data="${WORKING_FOLDER}/${day}_gps_data_concat.csv"
    if (( ${#logs_gps_csv_data[@]} > 0)); then
    cat "${logs_gps_csv_data[@]}" > "${concatenated_csv_data}"
    fi
    echo "${concatenated_csv_data}"
}


#converts a list of fit files into a "concatenated" CSV records
# $1 clip_basename the file name of the clip
# $@ all fit files
# outputs to STDOUT the path to clean CSV record file
function __fit_to_csv_records {
    local clip_basename
    clip_basename="$1"
    shift

    #warning: this is an array variable
    declare -a logs_gps_csv_data
    logs_gps_csv_data=()
    #shellcheck disable=SC2068
    for fit_file in $@; do
    local csv_file
    csv_file=$(basename "${fit_file}")
    csv_file="${WORKING_FOLDER}/${csv_file}"

    csv_file=$(__fit_to_csv "${fit_file}" "${csv_file}")

    #csvtool col 1,4,5,6 "${csv_file}" > "${csv_file}_interesting_cols"

        local namedcol
    namedcol='record.timestamp[s]'
    namedcol+=',record.distance[m]'
    namedcol+=',record.altitude[m]'
    namedcol+=',record.speed[m/s]'
    namedcol+=',record.cadence[rpm]'
    #add column 'record.heart_rate[bpm]' only if available
    if grep --quiet 'record.heart_rate' "${csv_file}" ; then
        namedcol+=',record.heart_rate[bpm]'
    fi

    csvtool namedcol "${namedcol}" "${csv_file}" \
        > "${csv_file}_interesting_cols"

    csv_file="${csv_file}_interesting_cols"
        __remove_header "${csv_file}"
        csv_file="${csv_file}_noheader"
    logs_gps_csv_data+=("${csv_file}")
    done

    local concatenated_csv_data
    concatenated_csv_data="${WORKING_FOLDER}/${clip_basename}_concat.csv"
    if (( ${#logs_gps_csv_data[@]} > 0)); then
    cat "${logs_gps_csv_data[@]}" > "${concatenated_csv_data}"
    fi
    echo "${concatenated_csv_data}"
}

#Converts a list of FIT files into short concatenated CSV files
#Globals:
#Arguments:
# $1 clip file (used for date matching and output filename)
# $2 the elapsed time offset in seconds
# $@ all fit files of the same day
#Outputs: the filename that can be used by ffmpeg drawtext filter
#Returns:
function _convert_fit_to_drawtext_cmd {
    local clip
    clip="$1"
    local clip_basename
    clip_basename=$(basename "${clip}")

    local elapsed_offset
    elapsed_offset="$2"
    shift
    shift

    local concatenated_csv_data
    concatenated_csv_data=$(__fit_to_csv_records "${clip_basename}" "$@")
    __msg_debug "concatenated_csv_data=${concatenated_csv_data}"
    local start
    start=$(__get_clip_start_date "${clip}")
    start=$(__unix_to_garmin_ts "${start}")
    local end
    end=$(__get_clip_end_date "${clip}")
    end=$(__unix_to_garmin_ts "${end}")

    #filter log lines having their first column (awk's $1) between $start and $end
    awk "${start} < \$1 && \$1 < ${end}" \
    < "${concatenated_csv_data}" \
    > "${concatenated_csv_data}_filtered"
    __msg_debug "concatenated_csv_data_filtered=
    ${concatenated_csv_data}_filtered}"

    local cmd_file
    cmd_file="${WORKING_FOLDER}/${clip_basename}.cmd_ffmpeg"
    __convert_csv_to_cmd "${concatenated_csv_data}_filtered" \
                         "${cmd_file}" \
                         "${elapsed_offset}"
    echo "${cmd_file}"
}
