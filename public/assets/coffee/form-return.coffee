$ ->
  holidays = eval $("input[name=return-date]").data('holidays')

  disabledDates = holidays

  disabledDates.push(
    '2022-01-27', '2022-01-28', '2022-01-29', '2022-01-30',
    '2022-01-31', '2022-02-01', '2022-02-02', '2022-02-03',
  )

  $("input[name=return-date]").datepicker(
    language: 'kr'
    todayHighlight: true
    autoclose:      true
    startDate: '+3d'
    daysOfWeekDisabled: [0, 6]
    datesDisabled: disabledDates
  )
