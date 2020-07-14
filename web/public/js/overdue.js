(function () {


    function handleClick(evt) {
        const target = evt.target;
        target.innerHTML = target.title;
        target.removeEventListener('click', handleClick);
    }

    let reminderDescrs = document.querySelectorAll('.reminder-descr');

    reminderDescrs.forEach((elem) => {
        elem.addEventListener('click', handleClick);
    })

})();