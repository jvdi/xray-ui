const oneMinute = 1000 * 60; // Number of milliseconds in a minute
const oneHour = oneMinute * 60; // Number of milliseconds in an hour
const oneDay = oneHour * 24; // Number of milliseconds in a day
const oneWeek = oneDay * 7; // Number of milliseconds in a week
const oneMonth = oneDay * 30; // Number of milliseconds in a month

/**
 * Decrease by number of days
 *
 * @param days Number of days to be reduced
 */
Date.prototype.minusDays = function (days) {
    return this.minusMillis(oneDay * days);
};

/**
 * Increase by days
 *
 * @param days Number of days to be added
 */
Date.prototype.plusDays = function (days) {
    return this.plusMillis(oneDay * days);
};

/**
 * Decrease by hour
 *
 * @param hours Number of hours to be reduced
 */
Date.prototype.minusHours = function (hours) {
    return this.minusMillis(oneHour * hours);
};

/**
 * Increase by hour
 *
 * @param hours Number of hours to be added
 */
Date.prototype.plusHours = function (hours) {
    return this.plusMillis(oneHour * hours);
};

/**
 * Decrease by minute
 *
 * @param minutes Number of minutes to be reduced
 */
Date.prototype.minusMinutes = function (minutes) {
    return this.minusMillis(oneMinute * minutes);
};

/**
 * Increases by minute
 *
 * @param minutes Number of minutes to be added
 */
Date.prototype.plusMinutes = function (minutes) {
    return this.plusMillis(oneMinute * minutes);
};

/**
 * Decrease by milliseconds
 *
 * @param millis Number of milliseconds to be reduced
 */
Date.prototype.minusMillis = function(millis) {
    let time = this.getTime() - millis;
    let newDate = new Date();
    newDate.setTime(time);
    return newDate;
};

/**
 * Increases by milliseconds
 *
 * @param millis Number of milliseconds to be added
 */
Date.prototype.plusMillis = function(millis) {
    let time = this.getTime() + millis;
    let newDate = new Date();
    newDate.setTime(time);
    return newDate;
};

/**
 * Set the time to the day of 00:00:00.000
 */
Date.prototype.setMinTime = function () {
    this.setHours(0);
    this.setMinutes(0);
    this.setSeconds(0);
    this.setMilliseconds(0);
    return this;
};

/**
 * Set the time to the day of 23:59:59.999
 */
Date.prototype.setMaxTime = function () {
    this.setHours(23);
    this.setMinutes(59);
    this.setSeconds(59);
    this.setMilliseconds(999);
    return this;
};

/**
 * Formatting Date
 */
Date.prototype.formatDate = function () {
    return this.getFullYear() + "-" + addZero(this.getMonth() + 1) + "-" + addZero(this.getDate());
};

/**
 * Formatting time
 */
Date.prototype.formatTime = function () {
    return addZero(this.getHours()) + ":" + addZero(this.getMinutes()) + ":" + addZero(this.getSeconds());
};

/**
 * Formatted date plus time
 *
 * @param split Separator between date and time, default is a space
 */
Date.prototype.formatDateTime = function (split = ' ') {
    return this.formatDate() + split + this.formatTime();
};

class DateUtil {

    // String to Date object
    static parseDate(str) {
        return new Date(str.replace(/-/g, '/'));
    }

    static formatMillis(millis) {
        return moment(millis).format('YYYY-M-D H:m:s')
    }

    static firstDayOfMonth() {
        const date = new Date();
        date.setDate(1);
        date.setMinTime();
        return date;
    }
}