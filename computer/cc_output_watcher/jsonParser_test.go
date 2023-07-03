package main

import "testing"

func Test_ingestMonitorDataToRedis(t *testing.T) {
	type args struct {
		filePath string
	}
	tests := []struct {
		name string
		args args
	}{
		{
			name: "1",
			args: args{
				filePath: `E:\minecraft_servers\direwolf20_1.12\world\computercraft\computer\40\monitorData.json`,
			},
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			ingestMonitorDataToRedis(tt.args.filePath)
		})
	}
}
