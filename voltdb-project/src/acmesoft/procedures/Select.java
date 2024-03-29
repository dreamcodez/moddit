package acmesoft.procedures;

import org.voltdb.*;

/** A VoltDB stored procedure is a Java class defining one or
 * more SQL statements and implementing a <code>public
 * VoltTable[] run</code> method. VoltDB requires a
 * <code>ProcInfo</code> annotation providing metadata for the
 * procedure.  The <code>run</code> method is
 * defined to accept one or more parameters. These parameters take the
 * values the client passes via the
 * <code>Client.callProcedure</code> invocation.
 *
 * The <a href="https://community.voltdb.com/documentation">VoltDB
 * User Guide</a> specifies valid stored procedure definitions,
 * including valid run method parameter types, required annotation
 * metadata, and correct use the Volt query interface.
*/
@ProcInfo(
    partitionInfo = "NEPTUNE2.NEPTUNE2_ID: 0",
    singlePartition = true
)
public class Select extends VoltProcedure {

    public final SQLStmt selectItem =
      new SQLStmt("SELECT NEPTUNE2_ID,  NEPTUNE2_ITEM " +
                  "FROM NEPTUNE2 WHERE  NEPTUNE2_ID = ?");

    public VoltTable[] run( int NEPTUNE2_ID ) throws VoltAbortException {
        // Add a SQL statement to the current execution queue
        voltQueueSQL( selectItem, NEPTUNE2_ID );

        // Run all queued queries.
        // Passing true parameter since this is the last voltExecuteSQL for this procedure.
        return voltExecuteSQL(true);
    }
}
