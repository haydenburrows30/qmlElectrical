#include "realtimezoomscroll.h"
#include <sstream>
#include <math.h>


static const int DataInterval = 100;


RealTimeZoomScroll::RealTimeZoomScroll(QObject *parent) : QObject(parent)
{
    m_currentChart = 0;

    // Clear data arrays to Chart::NoValue
    for (int i = 0; i < sampleSize; ++i)
        m_timeStamps[i] = m_dataSeriesA[i] = m_dataSeriesB[i] = m_dataSeriesC[i] = Chart::NoValue;
    m_currentIndex = 0;

    // Set m_nextDataTime to the current time. It is used by the real time random number
    // generator so it knows what timestamp should be used for the next data point.
    m_nextDataTime = QDateTime::currentDateTime();
}

RealTimeZoomScroll::~RealTimeZoomScroll()
{
    delete m_currentChart;
}

//
// The data acquisition routine. In this demo, this is invoked every DataInterval.
//
void RealTimeZoomScroll::getData()
{
    // The current time
    QDateTime now = QDateTime::currentDateTime();

    // This is our formula for the random number generator
    do
    {
        // We need the currentTime in millisecond resolution
        qint64 t = m_nextDataTime.toMSecsSinceEpoch();
        double currentTime = Chart::chartTime2((int)(t / 1000)) + (t % 1000)  / DataInterval
            * DataInterval / 1000.0;

        // Get a data sample
        double p = currentTime * 4;
        double dataA = 20 + cos(p * 129241) * 10 + 1 / (cos(p) * cos(p) + 0.01);
        double dataB = 150 + 100 * sin(p / 27.7) * sin(p / 10.1);
        double dataC = 150 + 100 * cos(p / 6.7) * cos(p / 11.9);

        // In this demo, if the data arrays are full, the oldest 5% of data are discarded.
        if (m_currentIndex >= sampleSize)
        {
            m_currentIndex = sampleSize * 95 / 100 - 1;

            for(int i = 0; i < m_currentIndex; ++i)
            {
                int srcIndex = i + sampleSize - m_currentIndex;
                m_timeStamps[i] = m_timeStamps[srcIndex];
                m_dataSeriesA[i] = m_dataSeriesA[srcIndex];
                m_dataSeriesB[i] = m_dataSeriesB[srcIndex];
                m_dataSeriesC[i] = m_dataSeriesC[srcIndex];
            }
        }

        // Store the new values in the current index position, and increment the index.
        m_timeStamps[m_currentIndex] = currentTime;
        m_dataSeriesA[m_currentIndex] = dataA;
        m_dataSeriesB[m_currentIndex] = dataB;
        m_dataSeriesC[m_currentIndex] = dataC;
        ++m_currentIndex;

        m_nextDataTime = m_nextDataTime.addMSecs(DataInterval);
    }
    while (m_nextDataTime < now);

    //
    // We provide some visual feedback to the latest numbers generated, so you can see the
    // data being generated.
    //
    m_ValueA = m_dataSeriesA[m_currentIndex - 1];
    m_ValueB = m_dataSeriesB[m_currentIndex - 1];
    m_ValueC = m_dataSeriesC[m_currentIndex - 1];
}

//
// Update the chart and the viewport periodically
//
void RealTimeZoomScroll::updateChart(QmlChartViewer *viewer)
{
    if (m_currentIndex > 0)
    {
        //
        // As we added more data, we may need to update the full range of the viewport.
        //

        double startDate = m_timeStamps[0];
        double endDate = m_timeStamps[m_currentIndex - 1];

        // Use the initialFullRange (which is 60 seconds in this demo) if this is sufficient.
        double duration = endDate - startDate;
        if (duration < initialFullRange)
            endDate = startDate + initialFullRange;

        // Update the full range to reflect the actual duration of the data. In this case,
        // if the view port is viewing the latest data, we will scroll the view port as new
        // data are added. If the view port is viewing historical data, we would keep the
        // axis scale unchanged to keep the chart stable.
        int updateType = Chart::ScrollWithMax;
        if (viewer->getViewPortLeft() + viewer->getViewPortWidth() < 0.999)
            updateType = Chart::KeepVisibleRange;
        bool scaleHasChanged = viewer->updateFullRangeH("x", startDate, endDate, updateType);

        // Set the zoom in limit as a ratio to the full range
        viewer->setZoomInWidthLimit(zoomInLimit / (viewer->getValueAtViewPort("x", 1) -
            viewer->getValueAtViewPort("x", 0)));

        // Trigger the viewPortChanged event to update the display if the axis scale has changed
        // or if new data are added to the existing axis scale.
        if (scaleHasChanged || (duration < initialFullRange))
            viewer->updateViewPort(true, false);
    }
}

//
// Draw chart
//
void RealTimeZoomScroll::drawChart(QmlChartViewer *viewer)
{
    // Get the start date and end date that are visible on the chart.
    double viewPortStartDate = viewer->getValueAtViewPort("x", viewer->getViewPortLeft());
    double viewPortEndDate = viewer->getValueAtViewPort("x", viewer->getViewPortLeft() +
        viewer->getViewPortWidth());

    // Extract the part of the data arrays that are visible.
    DoubleArray viewPortTimeStamps;
    DoubleArray viewPortDataSeriesA;
    DoubleArray viewPortDataSeriesB;
    DoubleArray viewPortDataSeriesC;

    if (m_currentIndex > 0)
    {
        // Get the array indexes that corresponds to the visible start and end dates
        int startIndex = (int)floor(Chart::bSearch(DoubleArray(m_timeStamps, m_currentIndex), viewPortStartDate));
        int endIndex = (int)ceil(Chart::bSearch(DoubleArray(m_timeStamps, m_currentIndex), viewPortEndDate));
        int noOfPoints = endIndex - startIndex + 1;

        // Extract the visible data
        viewPortTimeStamps = DoubleArray(m_timeStamps+ startIndex, noOfPoints);
        viewPortDataSeriesA = DoubleArray(m_dataSeriesA + startIndex, noOfPoints);
        viewPortDataSeriesB = DoubleArray(m_dataSeriesB + startIndex, noOfPoints);
        viewPortDataSeriesC = DoubleArray(m_dataSeriesC + startIndex, noOfPoints);
    }

    //
    // At this stage, we have extracted the visible data. We can use those data to plot the chart.
    //

    //================================================================================
    // Configure overall chart appearance.
    //================================================================================

    // Create an XYChart object of size 640 x 350 pixels
    XYChart *c = new XYChart(640, 350);

    // Set the plotarea at (55, 50) with width 80 pixels less than chart width, and height 80 pixels
    // less than chart height. Use a vertical gradient from light blue (f0f6ff) to sky blue (a0c0ff)
    // as background. Set border to transparent and grid lines to white (ffffff).
    c->setPlotArea(55, 50, c->getWidth() - 85, c->getHeight() - 80, c->linearGradientColor(0, 50, 0,
        c->getHeight() - 35, 0xf0f6ff, 0xa0c0ff), -1, Chart::Transparent, 0xffffff, 0xffffff);

    // As the data can lie outside the plotarea in a zoomed chart, we need enable clipping.
    c->setClipping();

    // Add a title to the chart using 18pt Arial font
    c->addTitle("    Realtime Chart with Zoom/Scroll and Track Line", "Arial", 18);

    // Add a legend box at (55, 25) using horizontal layout. Use 10pt Arial Bold as font. Set the
    // background and border color to transparent and use line style legend key.
    LegendBox *b = c->addLegend(55, 25, false, "Arial Bold", 10);
    b->setBackground(Chart::Transparent);
    b->setLineStyleKey();

    // Set the x and y axis stems to transparent and the label font to 10pt Arial
    c->xAxis()->setColors(Chart::Transparent);
    c->yAxis()->setColors(Chart::Transparent);
    c->xAxis()->setLabelStyle("Arial", 10);
    c->yAxis()->setLabelStyle("Arial", 10);

    // Set the y-axis tick length to 0 to disable the tick and put the labels closer to the axis.
    c->yAxis()->setTickLength(0);

    // Add axis title using 12pt Arial Bold Italic font
    c->yAxis()->setTitle("Ionic Temperature (C)", "Arial Bold", 12);

    //================================================================================
    // Add data to chart
    //================================================================================

    //
    // In this example, we represent the data by lines. You may modify the code below to use other
    // representations (areas, scatter plot, etc).
    //

    // Add a line layer for the lines, using a line width of 2 pixels
    LineLayer *layer = c->addLineLayer();
    layer->setLineWidth(2);
    layer->setFastLineMode();

    // Now we add the 3 data series to a line layer, using the color red (ff0000), green (00cc00)
    // and blue (0000ff)
    layer->setXData(viewPortTimeStamps);
    layer->addDataSet(viewPortDataSeriesA, 0xff0000, "Alpha");
    layer->addDataSet(viewPortDataSeriesB, 0x00cc00, "Beta");
    layer->addDataSet(viewPortDataSeriesC, 0x0000ff, "Gamma");

    //================================================================================
    // Configure axis scale and labelling
    //================================================================================

    // Set the x-axis as a date/time axis with the scale according to the view port x range.
    if (m_currentIndex > 0)
        c->xAxis()->setDateScale(viewPortStartDate, viewPortEndDate);

    // For the automatic axis labels, set the minimum spacing to 75/30 pixels for the x/y axis.
    c->xAxis()->setTickDensity(75);
    c->yAxis()->setTickDensity(30);

    //
    // In this demo, the time range can be from many hours to a few seconds. We can need to define
    // the date/time format the various cases.
    //

    // If all ticks are hour algined, we use "hh:nn<*br*>mmm dd" in bold font as the first label of
    // the Day, and "hh:nn" for other labels.
    c->xAxis()->setFormatCondition("align", 3600);
    c->xAxis()->setMultiFormat(Chart::StartOfDayFilter(), "<*font=bold*>{value|hh:nn<*br*>mmm dd}",
        Chart::AllPassFilter(), "{value|hh:nn}");

    // If all ticks are minute algined, then we use "hh:nn" as the label format.
    c->xAxis()->setFormatCondition("align", 60);
    c->xAxis()->setLabelFormat("{value|hh:nn}");

    // If all other cases, we use "hh:nn:ss" as the label format.
    c->xAxis()->setFormatCondition("else");
    c->xAxis()->setLabelFormat("{value|hh:nn:ss}");

    // We make sure the tick increment must be at least 1 second.
    c->xAxis()->setMinTickInc(1);

    //================================================================================
    // Output the chart
    //================================================================================

    // We need to update the track line too. If the mouse is moving on the chart (eg. if
    // the user drags the mouse on the chart to scroll it), the track line will be updated
    // in the MouseMovePlotArea event. Otherwise, we need to update the track line here.
    if (!viewer->isInMouseMoveEvent())
    {
        trackLineLabel(c, (0 == viewer->getChart()) ? c->getPlotArea()->getRightX() :
            viewer->getPlotAreaMouseX());
    }

    // Set the chart image to the QChartViewer
    delete viewer->getChart();
    viewer->setChart(m_currentChart = c);
}

//
// Draw track cursor when mouse is moving over plotarea
//
void RealTimeZoomScroll::drawTrackCursor(QmlChartViewer *viewer, int mouseX)
{
    trackLineLabel((XYChart *)viewer->getChart(), mouseX);
    viewer->updateDisplay();
}

//
// Draw the track line with legend
//
void RealTimeZoomScroll::trackLineLabel(XYChart *c, int mouseX)
{
    // Clear the current dynamic layer and get the DrawArea object to draw on it.
    DrawArea *d = c->initDynamicLayer();

    // The plot area object
    PlotArea *plotArea = c->getPlotArea();

    // Get the data x-value that is nearest to the mouse, and find its pixel coordinate.
    double xValue = c->getNearestXValue(mouseX);
    int xCoor = c->getXCoor(xValue);
    if (xCoor < plotArea->getLeftX())
        return;

    // Draw a vertical track line at the x-position
    d->vline(plotArea->getTopY(), plotArea->getBottomY(), xCoor, 0x888888);

    // Draw a label on the x-axis to show the track line position.
    std::ostringstream xlabel;
    xlabel << "<*font,bgColor=000000*> " << c->xAxis()->getFormattedLabel(xValue, "hh:nn:ss.ff")
        << " <*/font*>";
    TTFText *t = d->text(xlabel.str().c_str(), "Arial Bold", 10);

    // Restrict the x-pixel position of the label to make sure it stays inside the chart image.
    int xLabelPos = (std::max)(0, (std::min)(xCoor - t->getWidth() / 2, c->getWidth() - t->getWidth()));
    t->draw(xLabelPos, plotArea->getBottomY() + 6, 0xffffff);
    t->destroy();

    // Iterate through all layers to draw the data labels
    for (int i = 0; i < c->getLayerCount(); ++i) {
        Layer *layer = c->getLayerByZ(i);

        // The data array index of the x-value
        int xIndex = layer->getXIndexOf(xValue);

        // Iterate through all the data sets in the layer
        for (int j = 0; j < layer->getDataSetCount(); ++j)
        {
            DataSet *dataSet = layer->getDataSetByZ(j);
            const char *dataSetName = dataSet->getDataName();

            // Get the color, name and position of the data label
            int color = dataSet->getDataColor();
            int yCoor = c->getYCoor(dataSet->getPosition(xIndex), dataSet->getUseYAxis());

            // Draw a track dot with a label next to it for visible data points in the plot area
            if ((yCoor >= plotArea->getTopY()) && (yCoor <= plotArea->getBottomY()) && (color !=
                Chart::Transparent) && dataSetName && *dataSetName)
            {
                d->circle(xCoor, yCoor, 4, 4, color, color);

                std::ostringstream label;
                label << "<*font,bgColor=" << std::hex << color << "*> "
                    << c->formatValue(dataSet->getValue(xIndex), "{value|P4}") << " <*font*>";
                t = d->text(label.str().c_str(), "Arial Bold", 10);

                // Draw the label on the right side of the dot if the mouse is on the left side the
                // chart, and vice versa. This ensures the label will not go outside the chart image.
                if (xCoor <= (plotArea->getLeftX() + plotArea->getRightX()) / 2)
                    t->draw(xCoor + 6, yCoor, 0xffffff, Chart::Left);
                else
                    t->draw(xCoor - 6, yCoor, 0xffffff, Chart::Right);

                t->destroy();
            }
        }
    }
}

//
// User clicks on the Save Chart pushbutton
//
void RealTimeZoomScroll::saveChartImage(QmlChartViewer *viewer, QUrl url)
{
    QString path = url.toLocalFile();
    if (!path.isEmpty())
    {
        // Save the chart
        BaseChart *c = viewer->getChart();
        if (0 != c)
            c->makeChart(path.toUtf8().constData());
    }
}