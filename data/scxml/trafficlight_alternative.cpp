<?xml version="1.0" encoding="UTF-8"?>
<scxml version="1.0" xmlns="http://www.w3.org/2005/07/scxml" name="example_trafficlight" initial="redGoingYellow">
    <state id="redGoingYellow">
        <transition event="e1" target="yellowGoingGreen"/>
    </state>
    <state id="yellowGoingGreen">
        <transition event="e2" target="greenGoingYellow"/>
    </state>
    <state id="greenGoingYellow">
        <transition event="e3" target="yellowGoingRed"/>
    </state>
    <state id="yellowGoingRed">
        <transition event="e4" target="redGoingYellow"/>
    </state>
</scxml>
