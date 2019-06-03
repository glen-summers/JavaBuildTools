
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
	public static Parse(String path, String dep)
	{
		AstBuilder builder = new AstBuilder()
		List<ASTNode> nodes = builder.buildFromString( new String(Files.readAllBytes(Paths.get(path))) )

		Visitor visitor = new Visitor()
		for (ASTNode node : nodes)
		{
			node.visit(visitor)
		}

		int depsLastLine = visitor.getDepsLastLine()
		if (depsLastLine == -1)
		{
			throw new NoSuchElementException()
		}

		List<String> fileLines = Files.readAllLines(Paths.get(path))
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
}

Parser.Parse("../gradleSource/app/build.gradle", "    compile project(path: ':lib')")
Parser.Append("../gradleSource/settings.gradle", "include 'app', 'lib'")