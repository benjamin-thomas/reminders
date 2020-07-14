(function() {
    'use strict';

    var updateStandbyDateSection = document.getElementById('update-standby-date-section');
    var standbyDate = document.getElementById('reschedule_on');
    var nextStandbyOnWeekday = document.getElementById('next-standby-on-weekday');
    var $pushBack = $('#push-back');

    var elems = {
        months: document.getElementById('months'),
        weeks: document.getElementById('weeks'),
        days: document.getElementById('days'),
        hours: document.getElementById('hours'),
        minutes: document.getElementById('minutes')
    };

    function updateStandbyDate() {
        var mo = moment();

        var parse = function(elemKey) {
            var elem = elems[elemKey];
            if (elem.value === "" || elem === null) {
                return 0;
            }
            return parseInt(elem.value);
        };

        var months = parse('months'),
            weeks = parse('weeks'),
            days = parse('days'),
            hours = parse('hours'),
            minutes = parse('minutes');

        var update = function(n, type, randomizeHours, randomizeMinutes) {
            if (n === 0) {
                return;
            }
            mo.add(n, type);

            if (randomizeHours) {
                var h = parseInt(Math.random()*10) + 8; // 0-9 + 8 => 8..17
                mo.hours(h);
            }
            if (randomizeMinutes) {
                var m = parseInt(Math.random()*60); // 0-59
                mo.minutes(m);
            }
        };
        update(months, 'months', true, true);
        update(weeks, 'weeks', true, true);
        update(days, 'days', true, true);
        update(hours, 'hours', false, false);
        update(minutes, 'minutes', false, false);

        nextStandbyOnWeekday.innerText = "(" + weekday(mo.day()) + ")";
        standbyDate.value = mo.format("YYYY-MM-DDTHH:mm");
    }

    function weekday(n) {
        var days = new Array(7);
        days[0] = "dim";
        days[1] = "lun";
        days[2] = "mar";
        days[3] = "mer";
        days[4] = "jeu";
        days[5] = "ven";
        days[6] = "sam";

        return days[n];
    }

    function nextAt(e) {
        e.preventDefault();

        var hour;
        var dataHour = e.target.getAttribute('data-hour');
        if (dataHour === "rand") {
            hour = parseInt(Math.random()*8)+9; // 9-16
        } else {
            hour = parseInt(dataHour);
        }
        var minute = parseInt(Math.random()*60); // 0-59
        var mo = moment();
        mo.add(1, 'day');
        mo.hour(hour).minute(minute);
        standbyDate.value = mo.format("YYYY-MM-DDTHH:mm");
        standbyDate.focus();
        $pushBack.click();
    }

    // https://developer.mozilla.org/fr/docs/Web/JavaScript/Reference/Objets_globaux/Math/random
    function getRandomInt(min, max) {
        min = Math.ceil(min);
        max = Math.floor(max);
        return Math.floor(Math.random() * (max - min)) + min;
    }

    function todayAtRandom(e) {
        e.preventDefault();
        var minutes;

        var now = new Date();
        var endOfDay = new Date();
        endOfDay.setHours(17);
        endOfDay.setMinutes(0);

        var secondsRemaining = (endOfDay - now) / 1000;
        var randSeconds = getRandomInt(60*15, secondsRemaining);

        var mo = moment();
        mo.add(randSeconds, 'seconds');

        standbyDate.value = mo.format("YYYY-MM-DDTHH:mm");
        standbyDate.focus();
        $pushBack.click();
    }

    function todayAtEndOfDay(e) {
        e.preventDefault();
        var minutes;

        var now = new Date();
        var endOfDay = new Date();
        endOfDay.setHours(20);
        endOfDay.setMinutes(0);

        var secondsRemaining = (endOfDay - now) / 1000;

        var mo = moment();
        mo.add(secondsRemaining, 'seconds');

        standbyDate.value = mo.format("YYYY-MM-DDTHH:mm");
        standbyDate.focus();
        $pushBack.click();
    }

    updateStandbyDateSection.addEventListener('change', updateStandbyDate, false);
    document.getElementById('next-at').addEventListener('click', nextAt, false);
    document.getElementById('today-at-random').addEventListener('click', todayAtRandom, false);
    document.getElementById('today-at-end-of-day').addEventListener('click', todayAtEndOfDay, false);
    updateStandbyDate();
})();
