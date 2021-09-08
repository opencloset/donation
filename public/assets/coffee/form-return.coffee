$ ->
  holidays = eval $("input[name=return-date]").data('holidays')

  disabledDates = holidays

  disabledDates.push(
    '2021-09-17', '2021-09-18', '2021-09-19', '2021-09-20',
    '2021-09-21', '2021-09-22', '2021-09-23'
  )

  $("input[name=return-date]").datepicker(
    language: 'kr'
    todayHighlight: true
    autoclose:      true
    startDate: '+3d'
    daysOfWeekDisabled: [0, 6]
    datesDisabled: disabledDates
  )
