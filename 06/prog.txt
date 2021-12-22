import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileWriter;
import java.io.IOException;
import java.util.Map;
import java.util.Scanner;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;
import java.util.stream.Stream;

// Assembler for the Hack machine language, described in https://www.nand2tetris.org/_files/ugd/44046b_d70026d8c1424487a451eaba3e372132.pdf
class Assembler {

  public static final Pattern A_INSTRUCTION_CONSTANT = Pattern.compile("@(\\d+)");
  public static final Pattern A_INSTRUCTION = Pattern.compile("@(.*)");
  public static final Pattern C_INSTRUCTION = Pattern.compile("([ADM]+)?=?([^;]+);?([A-Z]+)?");
  public static final Pattern LABEL = Pattern.compile("\\((.+)\\)");
  static Map<String, String> computeTable = Stream.of(new String[][] {
      {"0", "101010"},
      {"1", "111111"},
      {"-1", "111010"},
      {"D", "001100"},
      {"X", "110000"},
      {"!D", "001101"},
      {"!X", "110001"},
      {"-D", "001111"},
      {"-X", "110011"},
      {"D+1", "011111"},
      {"X+1", "110111"},
      {"D-1", "001110"},
      {"X-1", "110010"},
      {"D+X", "000010"},
      {"D-X", "010011"},
      {"X-D", "000111"},
      {"D&X", "000000"},
      {"D|X", "010101"},
  }).collect(Collectors.toMap(e -> e[0], e -> e[1]));

  static Map<String, String> destinationTable = Stream.of(new String[][] {
      {null, "000"},
      {"M", "001"},
      {"D", "010"},
      {"MD", "011"},
      {"A", "100"},
      {"AM", "101"},
      {"AD", "110"},
      {"AMD", "111"},
  }).collect(Collectors.toMap(e -> e[0], e -> e[1]));

  static Map<String, String> jumpTable = Stream.of(new String[][] {
      {null, "000"},
      {"JGT", "001"},
      {"JEQ", "010"},
      {"JGE", "011"},
      {"JLT", "100"},
      {"JNE", "101"},
      {"JLE", "110"},
      {"JMP", "111"},
  }).collect(Collectors.toMap(e -> e[0], e -> e[1]));

  static Map<String, String> symbolTable = Stream.of(new String[][] {
      // predefined
      {"R0", "0"}, {"R1", "1"}, {"R2", "2"}, {"R3", "3"}, {"R4", "4"}, {"R5", "5"},
      {"R6", "6"}, {"R7", "7"}, {"R8", "8"}, {"R9", "9"}, {"R10", "10"},
      {"R11", "11"}, {"R12", "12"}, {"R13", "13"}, {"R14", "14"}, {"R15", "15"},
      {"SCREEN", "16384"}, {"KBD", "24576"}, {"SP", "0"}, {"LCL", "1"}, {"ARG", "2"},
      {"THIS", "3"}, {"THAT", "4"},
  }).collect(Collectors.toMap(e -> e[0], e -> e[1]));

  static int lastVariableSlot = 16;

  public static void main(String[] args) throws IOException {
    if (args.length != 1) {
      System.out.println("Usage: java assembler <path-to-asm>");
      return;
    }

    populateLabels(args[0]);

    int line = 0;
    try {
      StringBuilder binary = new StringBuilder();
      Scanner scanner = new Scanner(new File(args[0]));
      while (scanner.hasNext()) {
        String instruction = scanner.nextLine();
        line++;
        if (shouldSkip(instruction)) {
          continue;
        }
        String assemble = assemble(instruction);
        if (assemble != null && assemble.length() != 16) {
          throw new RuntimeException("Wrong instruction length for: " + instruction);
        }
        if (assemble != null) {
          binary.append(assemble).append("\n");
        }
      }
      scanner.close();
      FileWriter output = new FileWriter(args[0].replace(".asm", ".hack"));
      output.append(binary);
      output.close();
      System.out.println(binary);
    } catch (Throwable e) {
      System.err.printf("Error reading line %d\n", line);
      throw e;
    }
  }

  private static boolean shouldSkip(String instruction) {
    instruction = instruction.trim();
    return instruction.startsWith("//") || instruction.isEmpty();
  }

  private static void populateLabels(String fileName) throws FileNotFoundException {
    Scanner scanner = new Scanner(new File(fileName));
    int lineNumber = 0;
    while (scanner.hasNext()) {
      String line = scanner.nextLine();
      if (shouldSkip(line)) {
        continue;
      }
      Matcher matcher = LABEL.matcher(line);
      if (matcher.matches()) {
        String label = matcher.group(1);
        symbolTable.putIfAbsent(label, lineNumber + "");
        continue;
      }

      // only move the line number if this is not a label, because labels are not executable
      lineNumber++;
    }
  }

  private static String assemble(String instruction) {
    instruction = instruction.trim();
    int inlineComment = instruction.indexOf("//");
    if (inlineComment != -1) {
      instruction = instruction.substring(0, inlineComment);
    }

    if (LABEL.matcher(instruction).matches()) {
      return null;
    }

    Matcher isConstant = A_INSTRUCTION_CONSTANT.matcher(instruction);
    if (isConstant.matches()) {
      String constant = isConstant.group(1);
      return aInstructionFrom(constant);
    }

    Matcher aInstruction = A_INSTRUCTION.matcher(instruction);
    if (aInstruction.matches()) {
      String label = aInstruction.group(1);
      String value = symbolTable.get(label);
      if (value == null) {
        // insert new symbol
        value = lastVariableSlot + "";
        symbolTable.putIfAbsent(label, value);
        lastVariableSlot++;
      }
      return aInstructionFrom(value);
    }

    Matcher cIns = C_INSTRUCTION.matcher(instruction);
    if (cIns.matches()) {
      return cInstructionFrom(cIns);
    }

    return null;
  }

  private static String getCleanedGroup(String group) {
    if (group == null || group.isEmpty()) {
      return null;
    }

    return group.trim();
  }

  private static String cInstructionFrom(Matcher cIns) {
    String assembled = "111";
    String dest = getCleanedGroup(cIns.group(1));
    String compute = getCleanedGroup(cIns.group(2));
    String jmp = getCleanedGroup(cIns.group(3));

    assembled += compute != null && compute.contains("M") ? "1" : "0"; // a bit
    String normalized = compute != null ? compute.replace("A", "X").replace("M", "X") : null;
    String aluBits = computeTable.get(normalized);
    if (aluBits == null) {
      throw new RuntimeException("Failed to decode: " + normalized);
    }

    assembled += aluBits;

    assembled += destinationTable.get(dest);
    assembled += jumpTable.get(jmp);
    return assembled;
  }

  public static String aInstructionFrom(String constant) {
    return String.format("%16s", Integer.toBinaryString(Integer.parseInt(constant)))
        .replace(' ', '0');
  }
}