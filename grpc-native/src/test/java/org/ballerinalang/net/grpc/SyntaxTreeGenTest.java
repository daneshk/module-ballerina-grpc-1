package org.ballerinalang.net.grpc;

import io.ballerina.compiler.syntax.tree.SyntaxTree;
import io.ballerina.tools.text.TextDocument;
import io.ballerina.tools.text.TextDocuments;
import org.ballerinalang.net.grpc.protobuf.cmd.GrpcCmd;
import org.testng.Assert;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

/**
 * Tests Syntax tree generation.
 *
 * @since 0.8.0
 */
public class SyntaxTreeGenTest {

    private static final Path RES_DIR = Paths.get("src/test/resources/").toAbsolutePath();
    private static Path tempDir;
    private static Path inputDir;
    private static Path outputDir;

    @BeforeMethod
    public void setup() throws IOException {
        tempDir = Files.createTempDirectory("syntax-tree-gen-" + System.nanoTime());
        inputDir = RES_DIR.resolve("input");
        outputDir = RES_DIR.resolve("output");
    }

    @Test(description = "Generate syntax tree")
    public void testHelloWorld() {
        assertOutput("helloWorld.proto", "helloWorld_pb.bal", "");
    }

    private static void generateSourceCode(String sProtoFilePath, String sOutputDirPath, String mode) {

        Class<?> grpcCmdClass;
        try {
            grpcCmdClass = Class.forName("org.ballerinalang.net.grpc.protobuf.cmd.GrpcCmd");
            GrpcCmd grpcCmd = (GrpcCmd) grpcCmdClass.newInstance();
            Path protoFilePath = Paths.get(sProtoFilePath);
            Path outputDirPath = Paths.get(sOutputDirPath);
            grpcCmd.setBalOutPath(outputDirPath.toAbsolutePath().toString());
            grpcCmd.setProtoPath(protoFilePath.toAbsolutePath().toString());
            if (!mode.equals("")) {
                grpcCmd.setMode(mode);
            }
            grpcCmd.execute();
        } catch (ClassNotFoundException | IllegalAccessException | InstantiationException e) {
            throw new RuntimeException(e);
        }
    }

    private static void assertOutput(String input, String output, String mode) {
        Path protoFilePath = inputDir.resolve(input);
        Path expectedOutPath = outputDir.resolve(output);
        Path outputDirPath = tempDir.resolve("stubs");
        Path actualOutPath = outputDirPath.resolve(output);

        generateSourceCode(protoFilePath.toString(), outputDirPath.toString(), mode);

        Assert.assertTrue(Files.exists(actualOutPath));
        String expectedContent = null;
        try {
            expectedContent = Files.readString(expectedOutPath);
        } catch (IOException e) {
            Assert.fail("failed to read content of expected bal file", e);
        }
        String actualContent = null;
        try {
            actualContent = Files.readString(actualOutPath);
        } catch (IOException e) {
            Assert.fail("failed to read content of actual bal file", e);
        }
        TextDocument textDocument = TextDocuments.from(actualContent);
        Assert.assertFalse(SyntaxTree.from(textDocument).hasDiagnostics());

        Assert.assertEquals(
                actualContent.replaceAll("\\s+", ""),
                expectedContent.replaceAll("\\s+", "")
        );
    }
}