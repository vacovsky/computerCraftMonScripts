package main

import (
	"fmt"

	redistimeseries "github.com/RedisTimeSeries/redistimeseries-go"
)

var CLIENT *redistimeseries.Client = nil

func init() {
	CLIENT = redistimeseries.NewClient("192.168.111.56:6379", "nohelp", nil)
}

func redisTsWrite(keyName string, timeStamp int64, dataVal float64) {
	_, err := CLIENT.Add(keyName, timeStamp, dataVal)
	if err != nil {
		fmt.Println("Error:", err)
	}
}
