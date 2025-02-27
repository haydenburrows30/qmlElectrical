property int a
    property int b
    property int c

    ChartView {
        anchors.fill: parent
        antialiasing: true
        theme: ChartView.ChartThemeDark
        animationOptions: ChartView.SeriesAnimations

        ValueAxis {
            id: valueAxis
            min: 0
            max: 100
            tickCount: 2
        }

        ValueAxis {
            id: valueAxi
            min: -20
            max: 20
            tickCount: 3
        }

        Timer
        {
            interval: 250; running: true; repeat: true
            onTriggered:
            {
                if(c<40)
                {
                    b= Math.floor(Math.random()*(15-(-15)+1)+(-15));
                    c=c+1
                }
                else
                {
                    b= Math.floor(Math.random()*(35-(-35)+1)+(-35));
                    console.log(b)
                }

                if(c==40)
                {
                    valueAxi.min=-40
                    valueAxi.max=40
                }

                l1.append(a,b)

                if(a==100)
                {
                    l1.clear()
                    a=0
                    c=0
                }
                else
                {
                    a=a+1
                }
            }

        }

        SplineSeries {
            id:l1
            name: "LineSeries"
            axisX: valueAxis
            axisY: valueAxi
        }
    }