function updateBarChart() {
        barChart.removeAllSeries()
        let maxPercentVoltageDrop = 0  // Track highest voltage drop

        for (let i = 0; i < pythonModel.chart_data_qml.length; i++) {
            let entry = pythonModel.chart_data_qml[i]
            // create new barset for each cable type
            let barSet = BarSet {
                label: entry.cable
                append(entry.percentage_drop)
            }
            let barSeries = BarSeries {
                append(barSet)
                axisX: axisX
                axisY: axisY
                labelsVisible: true
                labelsPosition: AbstractBarSeries.LabelsOutsideEnd
                labelsPrecision: 2
                labelsAngle: 90
                labelsFormat: "@value %"
                barWidth: 0.9
            }
            barChart.addSeries(barSeries)

            // Track the highest voltage drop to set the Y-axis max value
            if (entry.percentage_drop > maxPercentVoltageDrop) {
                maxPercentVoltageDrop = entry.percentage_drop
            }
        }

        axisX.categories = ["Aluminium"] // ,"Copper"

        // Dynamically adjust Y-axis scale
        axisY.max = maxPercentVoltageDrop * 1.4  // Add 20% buffer for visibility
        axisY.min = 0
    }