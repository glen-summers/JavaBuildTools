
import org.codehaus.groovy.ast.ASTNode
import org.codehaus.groovy.ast.CodeVisitorSupport
import org.codehaus.groovy.ast.builder.AstBuilder
import org.codehaus.groovy.ast.expr.MethodCallExpression

import java.nio.file.Files
import java.nio.file.Paths

class Visitor extends CodeVisitorSupport
{
	private int depsLastLine = -1

	public int getDepsLastLine() { return depsLastLine }

	@Override
	public void visitMethodCallExpression(MethodCallExpression call)
	{
		if( depsLastLine == -1 && call.getMethodAsString().equals( "dependencies" ) )
		{
			depsLastLine = call.getLastLineNumber()
		}

		super.visitMethodCallExpression(call)
	}
}

class Parser
{
	public static AddDependency(String path, String dep)
	{
		def builder = new AstBuilder()
		def nodes = builder.buildFromString( new String(Files.readAllBytes(Paths.get(path))) )

		def visitor = new Visitor()
		for (def node : nodes)
		{
			node.visit(visitor)
		}

		int depsLastLine = visitor.getDepsLastLine()
		if (depsLastLine == -1)
		{
			throw new NoSuchElementException()
		}

		def fileLines = Files.readAllLines(Paths.get(path))
		fileLines.add(depsLastLine-1, "")
		fileLines.add(depsLastLine, dep)

		new File(path).withWriter()
		{ 
			for (def s : fileLines) { it.writeLine s }
		}
	}

	public static Append(String path, String value)
	{
		new File(path).append value
	}

	public static SetTestLogging(def file)
	{
		Append(file, "\r\n\
test {\r\n\
    testLogging {\r\n\
        events 'PASSED', 'FAILED', 'SKIPPED'\r\n\
    }\r\n\
}")
	}

	public static Main(def args)
	{
		def dir = args[0]
		def appFile = "$dir/app/build.gradle"
		def libFile = "$dir/lib/build.gradle"
		def rootSettings = "$dir/settings.gradle"

		AddDependency(appFile, "    compile project(path: ':lib')")
		SetTestLogging(appFile)
		SetTestLogging(libFile)
		Append(rootSettings, "include 'app', 'lib'")
	}
}

Parser.Main(args)
