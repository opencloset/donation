$ ->
  holidays = eval $("input[name=return-date]").data('holidays')

  disabledDates = holidays

  disabledDates.push(
    '2021-02-08', '2021-02-09', '2021-02-10', '2021-02-11',
    '2021-02-12', '2021-02-13', '2020-02-14'
  )

  $("input[name=return-date]").datepicker(
    language: 'kr'
    todayHighlight: true
    autoclose:      true
    startDate: '+3d'
    daysOfWeekDisabled: [0, 6]
    datesDisabled: disabledDates
  )
