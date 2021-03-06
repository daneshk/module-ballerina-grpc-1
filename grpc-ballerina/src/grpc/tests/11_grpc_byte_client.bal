// Copyright (c) 2018 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/io;
import ballerina/test;

type ByteArrayTypedesc typedesc<byte[]>;

@test:Config {}
function testByteArray() {
    byteServiceBlockingClient blockingEp  = new ("http://localhost:9101");
    string statement = "Lion in Town.";
    byte[] bytes = statement.toBytes();
    var addResponse = blockingEp->checkBytes(bytes);
    if (addResponse is Error) {
        test:assertFail(io:sprintf("Error from Connector: %s", addResponse.message()));
    } else {
        byte[] result = [];
        Headers resHeaders = new;
        [result, resHeaders] = addResponse;
        test:assertEquals(result, bytes);
    }
}

@test:Config {}
function testLargeByteArray() {
    string filePath = "src/grpc/tests/resources/sample_bytes.txt";
    byteServiceBlockingClient blockingEp  = new ("http://localhost:9101");
    var rch = <@untainted> io:openReadableFile(filePath);
    if (rch is error) {
        test:assertFail("Error while reading the file.");
    } else {
        var resultBytes = rch.read(10000);
        if (resultBytes is byte[]) {
            var addResponse = blockingEp->checkBytes(resultBytes);
            if (addResponse is Error) {
                test:assertFail(io:sprintf("Error from Connector: %s", addResponse.message()));
            } else {
                byte[] result = [];
                [result, _] = addResponse;
                test:assertEquals(result, resultBytes);
            }
        } else {
            error err = resultBytes;
            test:assertFail(io:sprintf("File read error: %s", err.message()));
        }
    }
}

public client class byteServiceBlockingClient {

    *AbstractClientEndpoint;

    private Client grpcClient;

    public isolated function init(string url, ClientConfiguration? config = ()) {
        // initialize client endpoint.
        self.grpcClient = new(url, config);
        checkpanic self.grpcClient.initStub(self, "blocking", ROOT_DESCRIPTOR_11, getDescriptorMap11());
    }

    public isolated remote function checkBytes (byte[] req, Headers? headers = ()) returns ([byte[], Headers]|Error) {
        var unionResp = check self.grpcClient->blockingExecute("grpcservices.byteService/checkBytes", req, headers);
        Headers resHeaders = new;
        anydata result = ();
        [result, resHeaders] = unionResp;
        var value = result.cloneWithType(ByteArrayTypedesc);
        if (value is byte[]) {
            return [value, resHeaders];
        } else {
            return InternalError("Error while constructing the message", value);
        }
    }
}

public client class byteServiceClient {

    *AbstractClientEndpoint;

    private Client grpcClient;

    public isolated function init(string url, ClientConfiguration? config = ()) {
        // initialize client endpoint.
        self.grpcClient = new(url, config);
        checkpanic self.grpcClient.initStub(self, "non-blocking", ROOT_DESCRIPTOR_11, getDescriptorMap11());
    }

    public isolated remote function checkBytes (byte[] req, service msgListener, Headers? headers = ()) returns (Error?) {
        return self.grpcClient->nonBlockingExecute("grpcservices.byteService/checkBytes", req, msgListener, headers);
    }
}
