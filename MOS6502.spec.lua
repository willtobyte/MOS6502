local MOS6502 = require("MOS6502")

local function assert_equal(actual, expected, msg)
  if actual ~= expected then
    local stack = debug.getinfo(2, "Sl")
    error(string.format("%s: expected %s, got %s (at %s:%d)",
      msg, tostring(expected), tostring(actual), stack.short_src, stack.currentline), 2)
    os.exit(1)
  end
end

local function it(description, fn)
  local status, err = pcall(fn)
  if status then
    print("passed - " .. description)
  else
    print("failed - " .. description .. "\n" .. err)
  end
end

-- KIL (0x02): Illegal Opcode – Halts the CPU
it("KIL: halts the CPU", function()
  local cpu = MOS6502.new()
  cpu:write(0x8000, 0x02) -- set opcode at 0x8000
  cpu:write(0xFFFC, 0x00) -- set reset vector low
  cpu:write(0xFFFD, 0x80) -- set reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.halted, true, "KIL must halt the CPU")
  assert_equal(cpu.cycles, 2, "KIL cycle count should be 2")
end)

-- ADC Immediate (0x69): Adds immediate value to A
it("ADC immediate: adds immediate 0x27 to A=3 without carry", function()
  local cpu = MOS6502.new()
  cpu.A = 3
  cpu.P = cpu.P & 0xFE    -- clear carry flag
  cpu:write(0x8000, 0x69) -- set ADC immediate opcode
  cpu:write(0x8001, 0x27) -- store operand 0x27
  cpu:write(0xFFFC, 0x00) -- set reset vector low
  cpu:write(0xFFFD, 0x80) -- set reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.A, 42, "ADC immediate should compute 3 + 39 = 42")
  assert_equal(cpu.cycles, 2, "ADC immediate cycle count should be 2")
end)

it("ADC immediate: adds immediate 0x27 to A=3 with carry set", function()
  local cpu = MOS6502.new()
  cpu:write(0x8000, 0x69) -- ADC immediate opcode at address 0x8000
  cpu:write(0x8001, 0x27) -- operand 0x27 (39 decimal)
  cpu:write(0xFFFC, 0x00) -- reset vector low byte
  cpu:write(0xFFFD, 0x80) -- reset vector high byte
  cpu:reset()

  -- Set A and the carry flag after reset.
  cpu.A = 3
  cpu.P = cpu.P | 0x01 -- set carry flag

  cpu:step()

  assert_equal(cpu.A, 43, "ADC immediate with carry should compute 3 + 39 + 1 = 43")
  assert_equal(cpu.cycles, 2, "ADC immediate with carry cycle count should be 2")
end)

-- ADC Zero Page (0x65): Adds value from zero page to A
it("ADC zero page: adds value from zero page to A", function()
  local cpu = MOS6502.new()
  cpu.A = 10
  cpu:write(0x0010, 20)   -- store 20 at ZP address 0x10
  cpu:write(0x8000, 0x65) -- set ADC zero page opcode
  cpu:write(0x8001, 0x10) -- operand: address 0x10
  cpu:write(0xFFFC, 0x00) -- set reset vector low
  cpu:write(0xFFFD, 0x80) -- set reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.A, 30, "ADC zero page should compute 10 + 20 = 30")
  assert_equal(cpu.cycles, 3, "ADC zero page cycle count should be 3")
end)

-- ADC Zero Page,X (0x75): Adds value from (base+X)
it("ADC zero page,X: adds value from (base+X) to A", function()
  local cpu = MOS6502.new()

  -- Write the value to be added into zero page at the effective address.
  -- With base address 0x20 and X = 5, the effective address is 0x20 + 5 = 0x25.
  cpu:write(0x0025, 10) -- store 10 at ZP address 0x25

  -- Write the ADC Zero Page,X instruction.
  cpu:write(0x8000, 0x75) -- ADC zero page,X opcode at address 0x8000
  cpu:write(0x8001, 0x20) -- base address 0x20 (effective address will be 0x20 + X)

  -- Set up the reset vector so that the CPU starts executing at 0x8000.
  cpu:write(0xFFFC, 0x00) -- reset vector low byte
  cpu:write(0xFFFD, 0x80) -- reset vector high byte

  cpu:reset()

  -- Set the registers after reset.
  cpu.A = 15 -- initial accumulator value
  cpu.X = 5  -- X register

  cpu:step()

  -- With A = 15, and value fetched = 10, ADC performs: 15 + 10 + (carry ? 1 : 0).
  -- Assuming no carry from previous operations, the result is 15 + 10 = 25.
  assert_equal(cpu.A, 25, "ADC zero page,X should compute 15 + 10 = 25")
  assert_equal(cpu.cycles, 4, "ADC zero page,X cycle count should be 4")
end)

-- ADC Absolute (0x6D): Adds value from absolute address to A
it("ADC absolute: adds value from absolute address to A", function()
  local cpu = MOS6502.new()
  cpu.A = 50
  cpu:write(0x1234, 25)   -- store 25 at absolute address 0x1234
  cpu:write(0x8000, 0x6D) -- set ADC absolute opcode
  cpu:write(0x8001, 0x34) -- low byte of address 0x1234
  cpu:write(0x8002, 0x12) -- high byte of address 0x1234
  cpu:write(0xFFFC, 0x00) -- set reset vector low
  cpu:write(0xFFFD, 0x80) -- set reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.A, 75, "ADC absolute should compute 50 + 25 = 75")
  assert_equal(cpu.cycles, 4, "ADC absolute cycle count should be 4")
end)

-- ADC Absolute,X (0x7D): Test without page crossing
it("ADC absolute,X (no cross): adds value from (absolute address + X) to A", function()
  local cpu = MOS6502.new()
  cpu.A = 30; cpu.X = 5
  cpu:write(0x1205, 10)   -- store 10 at address 0x1205 (0x1200+X)
  cpu:write(0x8000, 0x7D) -- set ADC absolute,X opcode
  cpu:write(0x8001, 0x00) -- low byte of base 0x1200
  cpu:write(0x8002, 0x12) -- high byte of base 0x1200
  cpu:write(0xFFFC, 0x00) -- set reset vector low
  cpu:write(0xFFFD, 0x80) -- set reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.A, 40, "ADC absolute,X (no cross) should compute 30 + 10 = 40")
  assert_equal(cpu.cycles, 4, "ADC absolute,X (no cross) cycle count should be 4")
end)

-- ADC Absolute,X with page crossing
it("ADC absolute,X (cross): adds value from (absolute address + X) to A with page cross", function()
  local cpu = MOS6502.new()
  cpu.A = 30; cpu.X = 20
  cpu:write(0x1304, 10)   -- store 10 at address 0x1304 (base 0x12F0 + X crosses page)
  cpu:write(0x8000, 0x7D) -- set ADC absolute,X opcode
  cpu:write(0x8001, 0xF0) -- low byte of base 0x12F0
  cpu:write(0x8002, 0x12) -- high byte of base 0x12
  cpu:write(0xFFFC, 0x00) -- set reset vector low
  cpu:write(0xFFFD, 0x80) -- set reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.A, 40, "ADC absolute,X (cross) should compute 30 + 10 = 40")
  assert_equal(cpu.cycles, 5, "ADC absolute,X (cross) cycle count should be 5")
end)

-- ADC Absolute,Y (0x79): Test without page crossing
it("ADC absolute,Y (no cross): adds value from (absolute address + Y) to A", function()
  local cpu = MOS6502.new()
  cpu.A = 20; cpu.Y = 3
  cpu:write(0x2003, 5)    -- store 5 at address 0x2003 (0x2000+Y)
  cpu:write(0x8000, 0x79) -- set ADC absolute,Y opcode
  cpu:write(0x8001, 0x00) -- low byte of base 0x2000
  cpu:write(0x8002, 0x20) -- high byte of base 0x2000
  cpu:write(0xFFFC, 0x00) -- set reset vector low
  cpu:write(0xFFFD, 0x80) -- set reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.A, 25, "ADC absolute,Y (no cross) should compute 20 + 5 = 25")
  assert_equal(cpu.cycles, 4, "ADC absolute,Y (no cross) cycle count should be 4")
end)

-- ADC Absolute,Y with page crossing
it("ADC absolute,Y (cross): adds value from (absolute address + Y) to A with page cross", function()
  local cpu = MOS6502.new()

  -- Set up the memory:
  -- We choose base = 0x2101. With Y = 0xFF, the effective address is 0x2101 + 0xFF = 0x2200.
  -- Write the value 5 at address 0x2200.
  cpu:write(0x2200, 5) -- store 5 at effective address 0x2200

  -- Write the ADC absolute,Y instruction.
  cpu:write(0x8000, 0x79) -- ADC absolute,Y opcode at address 0x8000
  cpu:write(0x8001, 0x01) -- low byte of base address (0x2101)
  cpu:write(0x8002, 0x21) -- high byte of base address (0x2101)

  -- Set up the reset vector so that the CPU begins execution at 0x8000.
  cpu:write(0xFFFC, 0x00) -- reset vector low byte
  cpu:write(0xFFFD, 0x80) -- reset vector high byte

  cpu:reset()

  -- Set the registers after reset.
  cpu.A = 20   -- initial accumulator value
  cpu.Y = 0xFF -- Y register value

  cpu:step()

  -- With A = 20 and memory value = 5 at 0x2200, ADC performs: 20 + 5 + (carry ? 1 : 0).
  -- Assuming no carry, the result should be 25.
  assert_equal(cpu.A, 25, "ADC absolute,Y (cross) should compute 20 + 5 = 25")
  assert_equal(cpu.cycles, 5, "ADC absolute,Y (cross) cycle count should be 5")
end)

-- ADC (Indirect,X) (0x61)
it("ADC (Indirect,X): adds value from pointer (ZP+X) to A", function()
  local cpu = MOS6502.new()
  cpu.A = 10; cpu.X = 1
  cpu:write(0x0010, 0xFF) -- store pointer low at ZP 0x10
  cpu:write(0x0011, 0x20) -- store pointer high at ZP 0x11 (pointer = 0x20FF)
  cpu:write(0x20FF, 15)   -- store 15 at effective address 0x20FF
  cpu:write(0x8000, 0x61) -- set ADC (Indirect,X) opcode
  cpu:write(0x8001, 0x0F) -- operand: ZP address 0x0F (0x0F+X = 0x10)
  cpu:write(0xFFFC, 0x00) -- set reset vector low
  cpu:write(0xFFFD, 0x80) -- set reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.A, 25, "ADC (Indirect,X) should compute 10 + 15 = 25")
  assert_equal(cpu.cycles, 6, "ADC (Indirect,X) cycle count should be 6")
end)

-- ADC (Indirect),Y (0x71) without page cross
it("ADC (Indirect),Y (no cross): adds value from pointer+Y to A", function()
  local cpu = MOS6502.new()
  cpu.A = 10; cpu.Y = 1
  cpu:write(0x0020, 0x00) -- store pointer low at ZP 0x20
  cpu:write(0x0021, 0x20) -- store pointer high at ZP 0x21 (pointer = 0x2000)
  cpu:write(0x2001, 15)   -- store 15 at address 0x2001 (0x2000+Y)
  cpu:write(0x8000, 0x71) -- set ADC (Indirect),Y opcode
  cpu:write(0x8001, 0x20) -- operand: ZP address 0x20
  cpu:write(0xFFFC, 0x00) -- set reset vector low
  cpu:write(0xFFFD, 0x80) -- set reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.A, 25, "ADC (Indirect),Y (no cross) should compute 10 + 15 = 25")
  assert_equal(cpu.cycles, 5, "ADC (Indirect),Y (no cross) cycle count should be 5")
end)

-- ADC (Indirect),Y (with page cross)
it("ADC (Indirect),Y (cross): adds value from pointer+Y to A with page cross", function()
  local cpu = MOS6502.new()

  -- Set initial accumulator and Y register.
  cpu.A = 10
  cpu.Y = 0xFF

  -- Set up the zero page pointer:
  -- Instead of 0x00, use 0x01 as the low byte so that 0x01 + 0xFF causes a page cross.
  cpu:write(0x0020, 0x01) -- store pointer low at ZP address 0x20
  cpu:write(0x0021, 0x20) -- store pointer high at ZP address 0x21 (pointer = 0x2001)

  -- Write the value to be added at the effective address.
  -- Effective address = pointer (0x2001) + Y (0xFF) = 0x2100.
  cpu:write(0x2100, 15) -- store 15 at address 0x2100

  -- Write the ADC (Indirect),Y instruction.
  cpu:write(0x8000, 0x71) -- ADC (Indirect),Y opcode at address 0x8000
  cpu:write(0x8001, 0x20) -- operand: zero page address 0x20

  -- Set the reset vector.
  cpu:write(0xFFFC, 0x00) -- reset vector low byte
  cpu:write(0xFFFD, 0x80) -- reset vector high byte

  cpu:reset()

  cpu:step()

  -- Calculation: A = 10, value = 15, so 10 + 15 = 25.
  -- With the page crossing, ADC (Indirect),Y should take 6 cycles.
  assert_equal(cpu.A, 25, "ADC (Indirect),Y (cross) should compute 10 + 15 = 25")
  assert_equal(cpu.cycles, 6, "ADC (Indirect),Y (cross) cycle count should be 6")
end)

-- BCC (0x90): Branch if Carry Clear
it("BCC: branches when carry flag is clear", function()
  local cpu = MOS6502.new()
  cpu.P = cpu.P & 0xFE    -- clear carry flag
  cpu:write(0x8000, 0x90) -- set BCC opcode
  cpu:write(0x8001, 0x05) -- store branch offset 0x05
  cpu:write(0xFFFC, 0x00) -- set reset vector low
  cpu:write(0xFFFD, 0x80) -- set reset vector high
  cpu:reset()
  local initPC = cpu.PC
  cpu:step()
  -- The branch target should be (initPC + 2 + offset)
  assert_equal(cpu.PC, (initPC + 2 + 5) & 0xFFFF, "BCC should branch when carry is clear")
  assert_equal(cpu.cycles, 3, "BCC (taken, no cross) cycle count should be 3")
end)

it("BCC: does not branch when carry flag is set", function()
  local cpu = MOS6502.new()

  cpu:write(0x8000, 0x90) -- BCC opcode at address 0x8000
  cpu:write(0x8001, 0x05) -- branch offset 0x05

  cpu:write(0xFFFC, 0x00) -- reset vector low byte
  cpu:write(0xFFFD, 0x80) -- reset vector high byte

  cpu:reset()

  -- Set the carry flag after reset so that the branch condition is false.
  cpu.P = cpu.P | 0x01

  local initPC = cpu.PC -- should be 0x8000 (32768)
  cpu:step()

  -- When the branch is not taken, the PC should advance by 2 bytes.
  assert_equal(cpu.PC, (initPC + 2) & 0xFFFF, "BCC should not branch when carry is set")
  assert_equal(cpu.cycles, 2, "BCC (not taken) cycle count should be 2")
end)

-- BCS (0xB0): Branch if Carry Set
it("BCS: branches when carry flag is set", function()
  local cpu = MOS6502.new()

  -- Write the BCS instruction at address 0x8000.
  cpu:write(0x8000, 0xB0) -- BCS opcode
  cpu:write(0x8001, 0x05) -- branch offset 0x05

  -- Set the reset vector so the CPU starts at 0x8000.
  cpu:write(0xFFFC, 0x00) -- reset vector low byte
  cpu:write(0xFFFD, 0x80) -- reset vector high byte

  cpu:reset()

  -- Set the carry flag after reset.
  cpu.P = cpu.P | 0x01

  local initPC = cpu.PC -- initial PC should be 0x8000.
  cpu:step()

  -- When the branch is taken, the target address should be: initPC + 2 + 5.
  assert_equal(cpu.PC, (initPC + 2 + 5) & 0xFFFF, "BCS should branch when carry is set")
  assert_equal(cpu.cycles, 3, "BCS (taken, no cross) cycle count should be 3")
end)

-- BCS (0xB0): Branch if Carry Set.
it("BCS: does not branch when carry flag is clear", function()
  local cpu = MOS6502.new()

  cpu:write(0x8000, 0xB0) -- BCS opcode at address 0x8000
  cpu:write(0x8001, 0x05) -- branch offset 0x05

  cpu:write(0xFFFC, 0x00) -- reset vector low byte
  cpu:write(0xFFFD, 0x80) -- reset vector high byte

  cpu:reset()

  -- Ensure the carry flag is cleared after reset.
  cpu.P = cpu.P & 0xFE

  local initPC = cpu.PC -- Expected to be 0x8000 (32768)
  cpu:step()

  -- When the branch is not taken, the PC should be initPC + 2.
  assert_equal(cpu.PC, (initPC + 2) & 0xFFFF, "BCS should not branch when carry flag is clear")
  assert_equal(cpu.cycles, 2, "BCS (not taken) cycle count should be 2")
end)

it("BMI: branches when negative flag is set", function()
  local cpu = MOS6502.new()

  cpu:write(0x8000, 0x30) -- BMI opcode at address 0x8000
  cpu:write(0x8001, 0x05) -- branch offset 0x05

  cpu:write(0xFFFC, 0x00) -- reset vector low byte
  cpu:write(0xFFFD, 0x80) -- reset vector high byte

  cpu:reset()

  -- Set the negative flag after reset so that the branch condition is met.
  cpu.P = cpu.P | 0x80

  local initPC = cpu.PC -- Expected to be 0x8000 if reset vector is 0x8000.
  cpu:step()

  -- When the branch is taken, the effective target should be:
  -- initPC + 2 (instruction length) + 5 (offset) = initPC + 7.
  assert_equal(cpu.PC, (initPC + 2 + 5) & 0xFFFF, "BMI should branch when negative flag is set")
  assert_equal(cpu.cycles, 3, "BMI (taken, no cross) cycle count should be 3")
end)

it("BMI: does not branch when negative flag is clear", function()
  local cpu = MOS6502.new()

  cpu:write(0x8000, 0x30) -- BMI opcode at address 0x8000
  cpu:write(0x8001, 0x05) -- branch offset 0x05

  cpu:write(0xFFFC, 0x00) -- reset vector low byte
  cpu:write(0xFFFD, 0x80) -- reset vector high byte

  cpu:reset()

  -- Clear the negative flag after reset so that the branch condition is not met.
  cpu.P = cpu.P & 0x7F

  local initPC = cpu.PC
  cpu:step()

  -- When BMI is not taken, the PC should advance by 2 bytes (opcode + offset).
  assert_equal(cpu.PC, (initPC + 2) & 0xFFFF, "BMI should not branch when negative flag is clear")
  assert_equal(cpu.cycles, 2, "BMI (not taken) cycle count should be 2")
end)

-- BNE (0xD0): Branch if Zero Clear
it("BNE: branches when zero flag is clear", function()
  local cpu = MOS6502.new()

  cpu:write(0x8000, 0xD0) -- BNE opcode at address 0x8000
  cpu:write(0x8001, 0x05) -- branch offset 0x05

  cpu:write(0xFFFC, 0x00) -- reset vector low byte
  cpu:write(0xFFFD, 0x80) -- reset vector high byte

  cpu:reset()

  -- Clear the zero flag after reset so that the branch is taken.
  cpu.P = cpu.P & 0xFD

  local initPC = cpu.PC -- Expected starting PC from the reset vector.
  cpu:step()

  -- When the branch is taken, the effective target should be:
  -- initPC + 2 (instruction length) + 5 (offset) = initPC + 7.
  assert_equal(cpu.PC, (initPC + 2 + 5) & 0xFFFF, "BNE should branch when zero flag is clear")
  assert_equal(cpu.cycles, 3, "BNE (taken, no cross) cycle count should be 3")
end)

it("BNE: does not branch when zero flag is set", function()
  local cpu = MOS6502.new()

  cpu:write(0x8000, 0xD0) -- BNE opcode at address 0x8000
  cpu:write(0x8001, 0x05) -- branch offset 0x05

  cpu:write(0xFFFC, 0x00) -- reset vector low byte
  cpu:write(0xFFFD, 0x80) -- reset vector high byte

  cpu:reset()

  -- Set the zero flag after reset so that the branch condition is not met.
  cpu.P = cpu.P | 0x02

  local initPC = cpu.PC -- Expected starting PC from the reset vector.
  cpu:step()

  -- When the branch is not taken, the PC should advance by 2 bytes (opcode + offset).
  assert_equal(cpu.PC, (initPC + 2) & 0xFFFF, "BNE should not branch when zero flag is set")
  assert_equal(cpu.cycles, 2, "BNE (not taken) cycle count should be 2")
end)

-- BPL (0x10): Branch if Negative Clear
it("BPL: branches when negative flag is clear", function()
  local cpu = MOS6502.new()

  cpu:write(0x8000, 0x10) -- BPL opcode at address 0x8000
  cpu:write(0x8001, 0x05) -- branch offset 0x05

  cpu:write(0xFFFC, 0x00) -- reset vector low byte
  cpu:write(0xFFFD, 0x80) -- reset vector high byte

  cpu:reset()

  -- Ensure the negative flag is clear after reset.
  cpu.P = cpu.P & 0x7F

  local initPC = cpu.PC
  cpu:step()

  -- When the branch is taken, the effective target address should be:
  -- initPC + 2 (instruction length) + 5 (offset) = initPC + 7.
  assert_equal(cpu.PC, (initPC + 2 + 5) & 0xFFFF, "BPL should branch when negative flag is clear")
  assert_equal(cpu.cycles, 3, "BPL (taken, no cross) cycle count should be 3")
end)

it("BPL: does not branch when negative flag is set", function()
  local cpu = MOS6502.new()

  cpu:write(0x8000, 0x10) -- BPL opcode at address 0x8000
  cpu:write(0x8001, 0x05) -- branch offset 0x05

  cpu:write(0xFFFC, 0x00) -- reset vector low byte
  cpu:write(0xFFFD, 0x80) -- reset vector high byte

  cpu:reset()

  -- Set the negative flag after reset so that the branch condition is false.
  cpu.P = cpu.P | 0x80

  local initPC = cpu.PC
  cpu:step()

  -- When the branch is not taken, the PC should advance by 2 bytes (opcode + offset).
  assert_equal(cpu.PC, (initPC + 2) & 0xFFFF, "BPL should not branch when negative flag is set")
  assert_equal(cpu.cycles, 2, "BPL (not taken) cycle count should be 2")
end)

-- BVC (0x50): Branch if Overflow Clear
it("BVC: branches when overflow flag is clear", function()
  local cpu = MOS6502.new()

  cpu:write(0x8000, 0x50) -- BVC opcode at address 0x8000
  cpu:write(0x8001, 0x05) -- branch offset 0x05

  cpu:write(0xFFFC, 0x00) -- reset vector low byte
  cpu:write(0xFFFD, 0x80) -- reset vector high byte

  cpu:reset()

  -- Ensure the overflow flag is clear after reset.
  cpu.P = cpu.P & 0xBF

  local initPC = cpu.PC -- Expected starting PC from the reset vector.
  cpu:step()

  -- When the branch is taken, the correct target address is:
  -- initPC + 2 (instruction length) + 5 (offset) = initPC + 7.
  assert_equal(cpu.PC, (initPC + 2 + 5) & 0xFFFF, "BVC should branch when overflow flag is clear")
  assert_equal(cpu.cycles, 3, "BVC (taken, no cross) cycle count should be 3")
end)

it("BVC: does not branch when overflow flag is set", function()
  local cpu = MOS6502.new()

  cpu:write(0x8000, 0x50) -- BVC opcode at address 0x8000
  cpu:write(0x8001, 0x05) -- branch offset 0x05

  cpu:write(0xFFFC, 0x00) -- reset vector low byte
  cpu:write(0xFFFD, 0x80) -- reset vector high byte

  cpu:reset()

  -- Set the overflow flag after reset so that the branch condition is not met.
  cpu.P = cpu.P | 0x40

  local initPC = cpu.PC -- Expected starting PC from the reset vector.
  cpu:step()

  -- When the branch is not taken, the PC should advance by 2 bytes (opcode + offset).
  assert_equal(cpu.PC, (initPC + 2) & 0xFFFF, "BVC should not branch when overflow flag is set")
  assert_equal(cpu.cycles, 2, "BVC (not taken) cycle count should be 2")
end)

-- BVS (0x70): Branch if Overflow Set
it("BVS: branches when overflow flag is set", function()
  local cpu = MOS6502.new()

  cpu:write(0x8000, 0x70) -- BVS opcode at address 0x8000
  cpu:write(0x8001, 0x05) -- branch offset 0x05

  cpu:write(0xFFFC, 0x00) -- reset vector low byte
  cpu:write(0xFFFD, 0x80) -- reset vector high byte

  cpu:reset()

  -- Set the overflow flag after reset so that the branch condition is met.
  cpu.P = cpu.P | 0x40

  local initPC = cpu.PC -- Expected starting PC from the reset vector.
  cpu:step()

  -- When the branch is taken, the effective target should be:
  -- initPC + 2 (instruction length) + 5 (offset) = initPC + 7.
  assert_equal(cpu.PC, (initPC + 2 + 5) & 0xFFFF, "BVS should branch when overflow is set")
  assert_equal(cpu.cycles, 3, "BVS (taken, no cross) cycle count should be 3")
end)

it("BVS: does not branch when overflow flag is clear", function()
  local cpu = MOS6502.new()

  cpu:write(0x8000, 0x70)   -- BVS opcode at address 0x8000
  cpu:write(0x8001, 0x05)   -- branch offset 0x05

  cpu:write(0xFFFC, 0x00)   -- reset vector low byte
  cpu:write(0xFFFD, 0x80)   -- reset vector high byte

  cpu:reset()

  -- Clear the overflow flag after reset so that the branch condition is not met.
  cpu.P = cpu.P & 0xBF

  local initPC = cpu.PC   -- Expected starting PC from the reset vector.
  cpu:step()

  -- When the branch is not taken, the PC should advance by 2 bytes (opcode + offset).
  assert_equal(cpu.PC, (initPC + 2) & 0xFFFF, "BVS should not branch when overflow flag is clear")
  assert_equal(cpu.cycles, 2, "BVS (not taken) cycle count should be 2")
end)

-- BIT Zero Page (0x24): Tests negative and overflow flags
it("BIT zero page: tests bit 7 into negative flag", function()
  local cpu = MOS6502.new()
  cpu.A = 0x0F
  cpu:write(0x0010, 0x80) -- store 0x80 at ZP 0x10
  cpu:write(0x8000, 0x24) -- set BIT zero page opcode
  cpu:write(0x8001, 0x10) -- operand: ZP 0x10
  cpu:write(0xFFFC, 0x00) -- set reset vector low
  cpu:write(0xFFFD, 0x80) -- set reset vector high
  cpu:reset()
  cpu:step()
  assert_equal((cpu.P & 0x80) ~= 0, true, "BIT should copy bit 7 to negative flag")
  assert_equal(cpu.cycles, 3, "BIT zero page cycle count should be 3")
end)

-- BIT Absolute (0x2C)
it("BIT absolute: tests bit 6 into overflow flag", function()
  local cpu = MOS6502.new()
  cpu.A = 0x0F
  cpu:write(0x1234, 0x40) -- store 0x40 at absolute 0x1234
  cpu:write(0x8000, 0x2C) -- set BIT absolute opcode
  cpu:write(0x8001, 0x34) -- low byte of address 0x1234
  cpu:write(0x8002, 0x12) -- high byte of address 0x1234
  cpu:write(0xFFFC, 0x00) -- set reset vector low
  cpu:write(0xFFFD, 0x80) -- set reset vector high
  cpu:reset()
  cpu:step()
  assert_equal((cpu.P & 0x40) ~= 0, true, "BIT should copy bit 6 to overflow flag")
  assert_equal(cpu.cycles, 4, "BIT absolute cycle count should be 4")
end)

-- BRK (0x00): Force Interrupt – Loads PC from IRQ vector
it("BRK: forces an interrupt and loads PC from the IRQ vector", function()
  local cpu = MOS6502.new()
  cpu:write(0x8000, 0x00) -- set BRK opcode
  cpu:write(0xFFFC, 0x00) -- set reset vector low
  cpu:write(0xFFFD, 0x80) -- set reset vector high
  cpu:write(0xFFFE, 0x00) -- set IRQ vector low
  cpu:write(0xFFFF, 0x90) -- set IRQ vector high (target 0x9000)
  cpu:reset()
  cpu:step()
  assert_equal(cpu.PC, 0x9000, "BRK should load PC from the IRQ vector")
  assert_equal(cpu.cycles, 7, "BRK cycle count should be 7")
end)

-- Flag Instructions – CLC, CLD, CLI, CLV
it("CLC: clears the carry flag", function()
  local cpu = MOS6502.new()
  cpu.P = 0xFF
  cpu:write(0x8000, 0x18) -- set CLC opcode
  cpu:write(0xFFFC, 0x00) -- set reset vector low
  cpu:write(0xFFFD, 0x80) -- set reset vector high
  cpu:reset()
  cpu:step()
  assert_equal((cpu.P & 0x01), 0, "CLC should clear the carry flag")
  assert_equal(cpu.cycles, 2, "CLC cycle count should be 2")
end)

it("CLD: clears the decimal flag", function()
  local cpu = MOS6502.new()
  cpu.P = 0xFF
  cpu:write(0x8000, 0xD8) -- set CLD opcode
  cpu:write(0xFFFC, 0x00) -- set reset vector low
  cpu:write(0xFFFD, 0x80) -- set reset vector high
  cpu:reset()
  cpu:step()
  assert_equal((cpu.P & 0x08), 0, "CLD should clear the decimal flag")
  assert_equal(cpu.cycles, 2, "CLD cycle count should be 2")
end)

it("CLI: clears the interrupt disable flag", function()
  local cpu = MOS6502.new()
  cpu.P = 0xFF
  cpu:write(0x8000, 0x58) -- set CLI opcode
  cpu:write(0xFFFC, 0x00) -- set reset vector low
  cpu:write(0xFFFD, 0x80) -- set reset vector high
  cpu:reset()
  cpu:step()
  assert_equal((cpu.P & 0x04), 0, "CLI should clear the interrupt disable flag")
  assert_equal(cpu.cycles, 2, "CLI cycle count should be 2")
end)

it("CLV: clears the overflow flag", function()
  local cpu = MOS6502.new()
  cpu.P = 0xFF
  cpu:write(0x8000, 0xB8) -- set CLV opcode
  cpu:write(0xFFFC, 0x00) -- set reset vector low
  cpu:write(0xFFFD, 0x80) -- set reset vector high
  cpu:reset()
  cpu:step()
  assert_equal((cpu.P & 0x40), 0, "CLV should clear the overflow flag")
  assert_equal(cpu.cycles, 2, "CLV cycle count should be 2")
end)

it("CMP immediate: compares A (50) with 50", function()
  local cpu = MOS6502.new()
  cpu.A = 50
  cpu:write(0x8000, 0xC9) -- set CMP immediate opcode
  cpu:write(0x8001, 50)   -- store operand 50
  cpu:write(0xFFFC, 0x00) -- set reset vector low
  cpu:write(0xFFFD, 0x80) -- set reset vector high
  cpu:reset()
  cpu:step()
  assert_equal((cpu.P & 0x01) ~= 0, true, "CMP immediate should set carry when A >= operand")
  assert_equal(cpu.cycles, 2, "CMP immediate cycle count should be 2")
end)

-- CPX Immediate (0xE0): Compare X with immediate
it("CPX immediate: compares X (30) with 30", function()
  local cpu = MOS6502.new()
  cpu.X = 30
  cpu:write(0x8000, 0xE0) -- set CPX immediate opcode
  cpu:write(0x8001, 30)   -- store operand 30
  cpu:write(0xFFFC, 0x00)
  cpu:write(0xFFFD, 0x80)
  cpu:reset()
  cpu:step()
  assert_equal((cpu.P & 0x01) ~= 0, true, "CPX immediate should set carry when X >= operand")
  assert_equal(cpu.cycles, 2, "CPX immediate cycle count should be 2")
end)

-- CPY Immediate (0xC0): Compare Y with immediate
it("CPY immediate: compares Y (60) with 60", function()
  local cpu = MOS6502.new()
  cpu.Y = 60
  cpu:write(0x8000, 0xC0) -- set CPY immediate opcode
  cpu:write(0x8001, 60)   -- store operand 60
  cpu:write(0xFFFC, 0x00)
  cpu:write(0xFFFD, 0x80)
  cpu:reset()
  cpu:step()
  assert_equal((cpu.P & 0x01) ~= 0, true, "CPY immediate should set carry when Y >= operand")
  assert_equal(cpu.cycles, 2, "CPY immediate cycle count should be 2")
end)

-- DEC Zero Page (0xC6): Decrements value in zero page memory
it("DEC zero page: decrements value at a zero page address", function()
  local cpu = MOS6502.new()
  cpu:write(0x0010, 5)    -- store 5 at ZP address 0x10
  cpu:write(0x8000, 0xC6) -- set DEC zero page opcode
  cpu:write(0x8001, 0x10) -- operand: address 0x10
  cpu:write(0xFFFC, 0x00) -- set reset vector low
  cpu:write(0xFFFD, 0x80) -- set reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu:read(0x0010), 4, "DEC zero page should decrement 5 to 4")
  assert_equal(cpu.cycles, 5, "DEC zero page cycle count should be 5")
end)

-- DEX (0xCA): Decrement X
it("DEX: decrements X", function()
  local cpu = MOS6502.new()
  cpu.X = 5
  cpu:write(0x8000, 0xCA) -- set DEX opcode
  cpu:write(0xFFFC, 0x00) -- set reset vector low
  cpu:write(0xFFFD, 0x80) -- set reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.X, 4, "DEX should decrement X from 5 to 4")
  assert_equal(cpu.cycles, 2, "DEX cycle count should be 2")
end)

-- DEY (0x88): Decrement Y
it("DEY: decrements Y", function()
  local cpu = MOS6502.new()
  cpu.Y = 5
  cpu:write(0x8000, 0x88) -- set DEY opcode
  cpu:write(0xFFFC, 0x00) -- set reset vector low
  cpu:write(0xFFFD, 0x80) -- set reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.Y, 4, "DEY should decrement Y from 5 to 4")
  assert_equal(cpu.cycles, 2, "DEY cycle count should be 2")
end)

-- EOR Immediate (0x49): Exclusive OR on A
it("EOR immediate: performs XOR on A with an immediate value", function()
  local cpu = MOS6502.new()
  cpu.A = 0xAA
  cpu:write(0x8000, 0x49) -- set EOR immediate opcode
  cpu:write(0x8001, 0xFF) -- store operand 0xFF
  cpu:write(0xFFFC, 0x00) -- set reset vector low
  cpu:write(0xFFFD, 0x80) -- set reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.A, 0x55, "EOR immediate should yield 0xAA XOR 0xFF = 0x55")
  assert_equal(cpu.cycles, 2, "EOR immediate cycle count should be 2")
end)

-- INC Zero Page (0xE6): Increment memory value
it("INC zero page: increments value at a zero page address", function()
  local cpu = MOS6502.new()
  cpu:write(0x0010, 5)    -- store 5 at ZP address 0x10
  cpu:write(0x8000, 0xE6) -- set INC zero page opcode
  cpu:write(0x8001, 0x10) -- operand: address 0x10
  cpu:write(0xFFFC, 0x00) -- set reset vector low
  cpu:write(0xFFFD, 0x80) -- set reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu:read(0x0010), 6, "INC zero page should increment 5 to 6")
  assert_equal(cpu.cycles, 5, "INC zero page cycle count should be 5")
end)

-- INX (0xE8): Increment X
it("INX: increments X", function()
  local cpu = MOS6502.new()
  cpu.X = 10
  cpu:write(0x8000, 0xE8) -- set INX opcode
  cpu:write(0xFFFC, 0x00) -- set reset vector low
  cpu:write(0xFFFD, 0x80) -- set reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.X, 11, "INX should increment X from 10 to 11")
  assert_equal(cpu.cycles, 2, "INX cycle count should be 2")
end)

-- INY (0xC8): Increment Y
it("INY: increments Y", function()
  local cpu = MOS6502.new()
  cpu.Y = 10
  cpu:write(0x8000, 0xC8) -- set INY opcode
  cpu:write(0xFFFC, 0x00) -- set reset vector low
  cpu:write(0xFFFD, 0x80) -- set reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.Y, 11, "INY should increment Y from 10 to 11")
  assert_equal(cpu.cycles, 2, "INY cycle count should be 2")
end)

-- JMP Absolute (0x4C): Jump to target address
it("JMP absolute: sets PC to target address", function()
  local cpu = MOS6502.new()
  cpu:write(0x8000, 0x4C) -- set JMP absolute opcode
  cpu:write(0x8001, 0x00) -- store low byte of target (0x9000)
  cpu:write(0x8002, 0x90) -- store high byte of target
  cpu:write(0xFFFC, 0x00) -- set reset vector low
  cpu:write(0xFFFD, 0x80) -- set reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.PC, 0x9000, "JMP absolute should load PC with target address")
  assert_equal(cpu.cycles, 3, "JMP absolute cycle count should be 3")
end)

-- JMP Indirect (0x6C): Jump using pointer (emulating bug)
it("JMP indirect: loads PC from pointer (emulating bug)", function()
  local cpu = MOS6502.new()

  -- Place the JMP indirect instruction in a safe region (0x8100)
  cpu:write(0x8100, 0x6C) -- JMP indirect opcode at 0x8100
  cpu:write(0x8101, 0xFF) -- Low byte of the pointer address
  cpu:write(0x8102, 0x80) -- High byte of the pointer address

  -- Set up the indirect vector.
  -- The pointer is 0x80FF. According to the bug, the low byte is read from 0x80FF...
  cpu:write(0x80FF, 0x00) -- Low byte of the target address
  -- ...and the high byte is read from 0x8000 (wrap-around), so we store 0x90 there.
  cpu:write(0x8000, 0x90) -- High byte of the target address (emulating bug)

  -- Set the reset vector to point to 0x8100 (where our JMP instruction resides)
  cpu:write(0xFFFC, 0x00) -- Reset vector low byte (0x8100 low = 0x00)
  cpu:write(0xFFFD, 0x81) -- Reset vector high byte (0x8100 high = 0x81)

  cpu:reset()
  cpu:step()

  -- The effective jump address should be assembled as:
  --   low byte:  memory[0x80FF] = 0x00
  --   high byte: memory[0x8000] = 0x90   (due to the bug)
  -- Thus, PC should be set to 0x9000.
  assert_equal(cpu.PC, 0x9000, "JMP indirect should load PC from pointer")
  assert_equal(cpu.cycles, 5, "JMP indirect cycle count should be 5")
end)

-- JSR (0x20): Jump to Subroutine – push return addr and jump
it("JSR: pushes return address and jumps to subroutine", function()
  local cpu = MOS6502.new()
  cpu:write(0x8000, 0x20) -- set JSR opcode
  cpu:write(0x8001, 0x00) -- store low byte of subroutine addr (0x9000)
  cpu:write(0x8002, 0x90) -- store high byte of subroutine addr
  cpu.PC = 0x8000
  cpu:write(0xFFFC, 0x00) -- set reset vector low
  cpu:write(0xFFFD, 0x80) -- set reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.PC, 0x9000, "JSR should jump to subroutine and push return address")
  assert_equal(cpu.cycles, 6, "JSR cycle count should be 6")
end)

-- LDA Immediate (0xA9): Load A with immediate
it("LDA immediate: loads immediate value into A", function()
  local cpu = MOS6502.new()
  cpu:write(0x8000, 0xA9) -- set LDA immediate opcode
  cpu:write(0x8001, 0x55) -- store operand 0x55
  cpu:write(0xFFFC, 0x00) -- set reset vector low
  cpu:write(0xFFFD, 0x80) -- set reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.A, 0x55, "LDA immediate should load 0x55 into A")
  assert_equal(cpu.cycles, 2, "LDA immediate cycle count should be 2")
end)

-- LDA Zero Page (0xA5): Load A from zero page
it("LDA zero page: loads value from zero page into A", function()
  local cpu = MOS6502.new()
  cpu:write(0x0010, 0xAA) -- store 0xAA at ZP address 0x10
  cpu:write(0x8000, 0xA5) -- set LDA zero page opcode
  cpu:write(0x8001, 0x10) -- operand: address 0x10
  cpu:write(0xFFFC, 0x00) -- set reset vector low
  cpu:write(0xFFFD, 0x80) -- set reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.A, 0xAA, "LDA zero page should load 0xAA into A")
  assert_equal(cpu.cycles, 3, "LDA zero page cycle count should be 3")
end)

-- LDA (Indirect,X) (0xA1): Load A from address via (ZP+X)
it("LDA (Indirect,X): loads value from pointer (ZP+X) into A", function()
  local cpu = MOS6502.new()

  -- Set up the pointer in zero page.
  cpu:write(0x0010, 0x10) -- store pointer low byte at ZP address 0x10
  cpu:write(0x0011, 0x40) -- store pointer high byte at ZP address 0x11 (forms pointer 0x4010)

  -- Set the value at the effective address.
  cpu:write(0x4010, 0x77) -- store 0x77 at effective address 0x4010

  -- Write the LDA (Indirect,X) opcode and operand.
  cpu:write(0x8000, 0xA1) -- LDA (Indirect,X) opcode at address 0x8000
  cpu:write(0x8001, 0x0F) -- operand: zero page address 0x0F; with X=1, 0x0F+1 = 0x10

  -- Set up the reset vector.
  cpu:write(0xFFFC, 0x00) -- reset vector low byte
  cpu:write(0xFFFD, 0x80) -- reset vector high byte

  cpu:reset()

  -- Set the X register to 1, so that (0x0F + X) = 0x10.
  cpu.X = 1

  cpu:step()

  assert_equal(cpu.A, 0x77, "LDA (Indirect,X) should load 0x77 into A")
  assert_equal(cpu.cycles, 6, "LDA (Indirect,X) cycle count should be 6")
end)

-- LDX Immediate (0xA2): Load X with immediate
it("LDX immediate: loads immediate value into X", function()
  local cpu = MOS6502.new()
  cpu:write(0x8000, 0xA2) -- set LDX immediate opcode
  cpu:write(0x8001, 0x33) -- store operand 0x33
  cpu:write(0xFFFC, 0x00) -- set reset vector low
  cpu:write(0xFFFD, 0x80) -- set reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.X, 0x33, "LDX immediate should load 0x33 into X")
  assert_equal(cpu.cycles, 2, "LDX immediate cycle count should be 2")
end)

-- LDY Immediate (0xA0): Load Y with immediate
it("LDY immediate: loads immediate value into Y", function()
  local cpu = MOS6502.new()
  cpu:write(0x8000, 0xA0) -- set LDY immediate opcode
  cpu:write(0x8001, 0x88) -- store operand 0x88
  cpu:write(0xFFFC, 0x00) -- set reset vector low
  cpu:write(0xFFFD, 0x80) -- set reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.Y, 0x88, "LDY immediate should load 0x88 into Y")
  assert_equal(cpu.cycles, 2, "LDY immediate cycle count should be 2")
end)

-- LSR Accumulator (0x4A): Logical Shift Right on A
it("LSR accumulator: shifts A right", function()
  local cpu = MOS6502.new()
  cpu.A = 0x03
  cpu:write(0x8000, 0x4A) -- set LSR accumulator opcode
  cpu:write(0xFFFC, 0x00) -- set reset vector low
  cpu:write(0xFFFD, 0x80) -- set reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.A, 0x01, "LSR accumulator should shift 0x03 to 0x01")
  assert_equal(cpu.cycles, 2, "LSR accumulator cycle count should be 2")
end)

-- ORA Immediate (0x09): Inclusive OR on A
it("ORA immediate: performs OR between A and immediate value", function()
  local cpu = MOS6502.new()
  cpu.A = 0x55
  cpu:write(0x8000, 0x09) -- set ORA immediate opcode
  cpu:write(0x8001, 0xAA) -- store operand 0xAA
  cpu:write(0xFFFC, 0x00) -- set reset vector low
  cpu:write(0xFFFD, 0x80) -- set reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.A, 0xFF, "ORA immediate should yield 0x55 OR 0xAA = 0xFF")
  assert_equal(cpu.cycles, 2, "ORA immediate cycle count should be 2")
end)

-- PHA (0x48): Push Accumulator onto the Stack
it("PHA: pushes the accumulator onto the stack", function()
  local cpu = MOS6502.new()
  cpu.A = 0x77
  cpu:write(0x8000, 0x48) -- set PHA opcode
  cpu:write(0xFFFC, 0x00) -- set reset vector low
  cpu:write(0xFFFD, 0x80) -- set reset vector high
  cpu:reset()
  cpu:step()
  local pushed = cpu:read(0x0100 + ((cpu.SP + 1) & 0xFF))
  assert_equal(pushed, 0x77, "PHA should push A onto the stack")
  assert_equal(cpu.cycles, 3, "PHA cycle count should be 3")
end)

-- PHP (0x08): Push Processor Status onto the Stack
it("PHP: pushes the processor status (with break flag set) onto the stack", function()
  local cpu = MOS6502.new()
  cpu:write(0x8000, 0x08) -- set PHP opcode at address 0x8000
  cpu:write(0xFFFC, 0x00) -- set reset vector low byte
  cpu:write(0xFFFD, 0x80) -- set reset vector high byte
  cpu:reset()

  -- Set the processor status after reset so it has the desired value.
  cpu.P = 0xAA

  cpu:step()

  -- When PHP executes, it pushes P with the break flag (bit 4) set.
  local pushed = cpu:read(0x0100 + ((cpu.SP + 1) & 0xFF))
  local expected = (0xAA | 0x10) & 0xFF -- expected value is 0xBA (186)
  assert_equal(pushed, expected, "PHP should push status with break flag set")
  assert_equal(cpu.cycles, 3, "PHP cycle count should be 3")
end)

-- PLA (0x68): Pull Accumulator from the Stack
it("PLA: pulls a value from the stack into A", function()
  local cpu = MOS6502.new()
  cpu:write(0x8000, 0x68) -- set PLA opcode at address 0x8000
  cpu:write(0xFFFC, 0x00) -- set reset vector low byte
  cpu:write(0xFFFD, 0x80) -- set reset vector high byte
  cpu:reset()

  -- Push the value after reset so that the stack pointer is in the correct state.
  cpu:push(0x99) -- push value 0x99 (153 in decimal)

  cpu:step()

  assert_equal(cpu.A, 0x99, "PLA should load A from the stack")
  assert_equal(cpu.cycles, 4, "PLA cycle count should be 4")
end)

-- PLP (0x28): Pull Processor Status from the Stack
it("PLP: pulls the processor status from the stack", function()
  local cpu = MOS6502.new()
  cpu:write(0x8000, 0x28) -- set PLP opcode at address 0x8000
  cpu:write(0xFFFC, 0x00) -- set reset vector low byte
  cpu:write(0xFFFD, 0x80) -- set reset vector high byte
  cpu:reset()

  -- Push the processor status after reset so that the stack pointer is correct.
  cpu:push(0xAA) -- push status 0xAA

  cpu:step()

  -- The expected restored status is (0xAA & 0xEF) | 0x20.
  assert_equal(cpu.P, (0xAA & 0xEF) | 0x20, "PLP should restore processor status from the stack")
  assert_equal(cpu.cycles, 4, "PLP cycle count should be 4")
end)

-- ROR Accumulator (0x6A): Rotates A right through carry
it("ROR accumulator: rotates A right through carry", function()
  local cpu = MOS6502.new()
  cpu:write(0x8000, 0x6A) -- set ROR accumulator opcode at address 0x8000
  cpu:write(0xFFFC, 0x00) -- set reset vector low byte
  cpu:write(0xFFFD, 0x80) -- set reset vector high byte
  cpu:reset()

  -- Set the initial state after reset
  cpu.A = 0x01         -- accumulator set to 0x01
  cpu.P = cpu.P | 0x01 -- set the carry flag

  cpu:step()

  assert_equal(cpu.A, 0x80, "ROR accumulator should rotate 0x01 with carry to yield 0x80")
  assert_equal(cpu.cycles, 2, "ROR accumulator cycle count should be 2")
end)

-- RTI (0x40): Return from Interrupt – restores PC and status
it("RTI: restores PC and status from the stack", function()
  local cpu = MOS6502.new()
  cpu:write(0x8000, 0x40) -- RTI opcode at address 0x8000
  cpu:write(0xFFFC, 0x00) -- Reset vector low byte
  cpu:write(0xFFFD, 0x80) -- Reset vector high byte
  cpu:reset()

  -- Push the bytes in the correct order:
  -- First push PC high byte, then PC low byte, then status.
  cpu:push(0x90) -- push high byte of PC (0x90)
  cpu:push(0x00) -- push low byte of PC (0x00)
  cpu:push(0xAA) -- push status (0xAA)

  cpu:step()

  assert_equal(cpu.PC, 0x9000, "RTI should restore PC from the stack")
  assert_equal(cpu.cycles, 6, "RTI cycle count should be 6")
end)

-- RTS (0x60): Return from Subroutine – restores PC (+1)
it("RTS: returns from subroutine by restoring PC", function()
  local cpu = MOS6502.new()
  cpu:write(0x8000, 0x60) -- RTS opcode at address 0x8000
  cpu:write(0xFFFC, 0x00) -- Reset vector low byte
  cpu:write(0xFFFD, 0x80) -- Reset vector high byte
  cpu:reset()

  -- For a return address of 0x7FFF, push the high byte first, then the low byte.
  cpu:push(0x7F) -- push high byte (0x7F)
  cpu:push(0xFF) -- push low byte (0xFF)

  cpu:step()

  assert_equal(cpu.PC, 0x8000, "RTS should set PC to return address + 1")
  assert_equal(cpu.cycles, 6, "RTS cycle count should be 6")
end)

-- SBC Immediate (0xE9): Subtracts immediate value from A
it("SBC immediate: subtracts immediate value from A with carry set", function()
  local cpu = MOS6502.new()
  cpu.A = 50
  cpu:write(0x8000, 0xE9) -- SBC immediate opcode
  cpu:write(0x8001, 20)   -- Immediate operand 20
  cpu:write(0xFFFC, 0x00) -- Reset vector low byte
  cpu:write(0xFFFD, 0x80) -- Reset vector high byte
  cpu:reset()
  cpu.P = cpu.P | 0x01    -- Set the carry flag after reset
  cpu:step()

  assert_equal(cpu.A, 30, "SBC immediate should compute 50 - 20 = 30")
  assert_equal(cpu.cycles, 2, "SBC immediate cycle count should be 2")
end)
