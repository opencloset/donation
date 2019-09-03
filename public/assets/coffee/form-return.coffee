$ ->
  holidays = eval $("input[name=return-date]").data('holidays')

  disabledDates = holidays

  disabledDates.push(
    '2019-09-07', '2019-09-08', '2019-09-09', '2019-09-10',
    '2019-09-11', '2019-09-12', '2019-09-13', '2019-09-14',
    '2019-09-15', '2019-09-16'
  )

  $("input[name=return-date]").datepicker(
    language: 'kr'
    todayHighlight: true
    autoclose:      true
    startDate: '+3d'
    daysOfWeekDisabled: [0, 6]
    datesDisabled: disabledDates
  )
