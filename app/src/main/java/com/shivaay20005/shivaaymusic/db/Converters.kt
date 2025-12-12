package com.shivaay20005.shivaaymusic.db

import androidx.room.TypeConverter
import java.time.Instant
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.ZoneOffset

class Converters {
    @TypeConverter
    fun fromTimestamp(value: Long?): LocalDateTime? =
        if (value != null) {
            LocalDateTime.ofInstant(Instant.ofEpochMilli(value), ZoneOffset.UTC)
        } else {
            null
        }

    @TypeConverter
    fun dateToTimestamp(date: LocalDateTime?): Long? =
        date?.atZone(ZoneOffset.UTC)?.toInstant()?.toEpochMilli()

    @TypeConverter
    fun fromDateLong(value: Long?): LocalDate? =
        if (value != null) {
            LocalDate.ofEpochDay(value)
        } else {
            null
        }

    @TypeConverter
    fun localDateToLong(date: LocalDate?): Long? =
        date?.toEpochDay()
}
