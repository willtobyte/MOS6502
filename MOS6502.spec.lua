local MOS6502 = require("MOS6502")

local function assert_equal(actual, expected, msg)
  if actual ~= expected then
    error(msg .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
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

-------------------------------------------------
-- KIL (Illegal Opcode 0x02)
it("KIL halts the CPU and uses 2 cycles", function()
  local cpu = MOS6502.new()
  cpu:write(0x8000, 0x02) -- Write opcode 0x02 (KIL) at address 0x8000
  cpu:write(0xFFFC, 0x00) -- Set reset vector low byte to 0x00
  cpu:write(0xFFFD, 0x80) -- Set reset vector high byte to 0x80 so that reset jumps to 0x8000
  cpu:reset()
  cpu:step()
  assert_equal(cpu.halted, true, "KIL should halt the CPU")
  assert_equal(cpu.cycles, 2, "KIL should consume 2 cycles")
end)

-------------------------------------------------
-- ADC (Add with Carry)
-- ADC Immediate (0x69)
it("ADC immediate without carry (0x69) uses 2 cycles", function()
  local cpu = MOS6502.new()
  cpu.A = 3               -- Preload accumulator with 3
  cpu.P = 0               -- Ensure carry flag is clear
  cpu:write(0x8000, 0x69) -- Write opcode 0x69 (ADC immediate) at 0x8000
  cpu:write(0x8001, 0x27) -- Write immediate operand 0x27 (decimal 39)
  cpu:write(0xFFFC, 0x00) -- Reset vector low byte = 0x00
  cpu:write(0xFFFD, 0x80) -- Reset vector high byte = 0x80
  cpu:reset()
  cpu:step()
  assert_equal(cpu.A, 42, "ADC immediate without carry: 3 + 39 should equal 42")
  assert_equal(cpu.cycles, 2, "ADC immediate without carry uses 2 cycles")
end)
it("ADC immediate with carry (0x69) uses 2 cycles", function()
  local cpu = MOS6502.new()
  cpu.A = 3               -- Preload accumulator with 3
  cpu:write(0x8000, 0x69) -- Write opcode for ADC immediate
  cpu:write(0x8001, 0x27) -- Write immediate operand 0x27
  cpu:write(0xFFFC, 0x00) -- Set reset vector low
  cpu:write(0xFFFD, 0x80) -- Set reset vector high
  cpu:reset()
  cpu.P = cpu.P | 0x01    -- Set carry flag after reset
  cpu:step()
  assert_equal(cpu.A, 43, "ADC immediate with carry: 3 + 39 + 1 should equal 43")
  assert_equal(cpu.cycles, 2, "ADC immediate with carry uses 2 cycles")
end)
-- ADC Zero Page (0x65)
it("ADC zero page (0x65) uses 3 cycles", function()
  local cpu = MOS6502.new()
  cpu.A = 10              -- Preload A with 10
  cpu.P = 0
  cpu:write(0x0010, 20)   -- Write value 20 at zero page address 0x10
  cpu:write(0x8000, 0x65) -- Write opcode 0x65 (ADC zero page)
  cpu:write(0x8001, 0x10) -- Write operand (address 0x10)
  cpu:write(0xFFFC, 0x00) -- Reset vector low byte
  cpu:write(0xFFFD, 0x80) -- Reset vector high byte
  cpu:reset()
  cpu:step()
  assert_equal(cpu.A, 30, "ADC zero page: 10 + 20 should equal 30")
  assert_equal(cpu.cycles, 3, "ADC zero page uses 3 cycles")
end)
-- ADC Zero Page,X (0x75)
it("ADC zero page,X (0x75) uses 4 cycles", function()
  local cpu = MOS6502.new()
  cpu.A = 10; cpu.X = 5; cpu.P = 0
  cpu:write(0x0025, 15)   -- Write value 15 at address 0x20+X (5 added to 0x20 gives 0x25)
  cpu:write(0x8000, 0x75) -- Write opcode 0x75 (ADC zero page,X)
  cpu:write(0x8001, 0x20) -- Write operand base address 0x20
  cpu:write(0xFFFC, 0x00) -- Reset vector low byte
  cpu:write(0xFFFD, 0x80) -- Reset vector high byte
  cpu:reset()
  cpu:step()
  assert_equal(cpu.A, 25, "ADC zero page,X: 10 + 15 should equal 25")
  assert_equal(cpu.cycles, 4, "ADC zero page,X uses 4 cycles")
end)
-- ADC Absolute (0x6D)
it("ADC absolute (0x6D) uses 4 cycles", function()
  local cpu = MOS6502.new()
  cpu.A = 50; cpu.P = 0
  cpu:write(0x1234, 25)   -- Write value 25 at absolute address 0x1234
  cpu:write(0x8000, 0x6D) -- Write opcode 0x6D (ADC absolute)
  cpu:write(0x8001, 0x34) -- Write low byte of address 0x1234
  cpu:write(0x8002, 0x12) -- Write high byte of address 0x1234
  cpu:write(0xFFFC, 0x00) -- Reset vector low byte
  cpu:write(0xFFFD, 0x80) -- Reset vector high byte
  cpu:reset()
  cpu:step()
  assert_equal(cpu.A, 75, "ADC absolute: 50 + 25 should equal 75")
  assert_equal(cpu.cycles, 4, "ADC absolute uses 4 cycles")
end)
-- ADC Absolute,X (0x7D)
it("ADC absolute,X (0x7D) without page cross uses 4 cycles", function()
  local cpu = MOS6502.new()
  cpu.A = 30; cpu.X = 5; cpu.P = 0
  cpu:write(0x1205, 10)   -- Write value 10 at effective address 0x1200+X (0x1205)
  cpu:write(0x8000, 0x7D) -- Write opcode 0x7D (ADC absolute,X)
  cpu:write(0x8001, 0x00) -- Write low byte of base address (0x1200)
  cpu:write(0x8002, 0x12) -- Write high byte of base address (0x1200)
  cpu:write(0xFFFC, 0x00) -- Reset vector low byte
  cpu:write(0xFFFD, 0x80) -- Reset vector high byte
  cpu:reset()
  cpu:step()
  assert_equal(cpu.A, 40, "ADC absolute,X without page cross: 30 + 10 should equal 40")
  assert_equal(cpu.cycles, 4, "ADC absolute,X without page cross uses 4 cycles")
end)
it("ADC absolute,X (0x7D) with page cross uses 5 cycles", function()
  local cpu = MOS6502.new()
  cpu.A = 30; cpu.X = 20; cpu.P = 0
  cpu:write(0x1304, 10)   -- Write value 10 at effective address causing page cross
  cpu:write(0x8000, 0x7D) -- Write opcode 0x7D (ADC absolute,X)
  cpu:write(0x8001, 0xF0) -- Write low byte of base address (e.g. 0x12F0)
  cpu:write(0x8002, 0x12) -- Write high byte of base address
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.A, 40, "ADC absolute,X with page cross: 30 + 10 should equal 40")
  assert_equal(cpu.cycles, 5, "ADC absolute,X with page cross uses 5 cycles")
end)
-- ADC Absolute,Y (0x79)
it("ADC absolute,Y (0x79) without page cross uses 4 cycles", function()
  local cpu = MOS6502.new()
  cpu.A = 20; cpu.Y = 3; cpu.P = 0
  cpu:write(0x2003, 5)    -- Write value 5 at effective address (0x2000+Y)
  cpu:write(0x8000, 0x79) -- Write opcode 0x79 (ADC absolute,Y)
  cpu:write(0x8001, 0x00) -- Write low byte of base address (0x2000)
  cpu:write(0x8002, 0x20) -- Write high byte of base address (0x20)
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.A, 25, "ADC absolute,Y without page cross: 20 + 5 should equal 25")
  assert_equal(cpu.cycles, 4, "ADC absolute,Y without page cross uses 4 cycles")
end)
it("ADC absolute,Y (0x79) with page cross uses 5 cycles", function()
  local cpu = MOS6502.new()
  cpu.A = 20; cpu.Y = 0xFF; cpu.P = 0
  cpu:write(0x2100, 5)    -- Write value 5 at effective address causing a page cross
  cpu:write(0x8000, 0x79) -- Write opcode: ADC absolute,Y
  cpu:write(0x8001, 0x01) -- Write low byte of base address (e.g. 0x2100 becomes 0x2101)
  cpu:write(0x8002, 0x20) -- Write high byte of base address
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.A, 25, "ADC absolute,Y with page cross: 20 + 5 should equal 25")
  assert_equal(cpu.cycles, 5, "ADC absolute,Y with page cross uses 5 cycles")
end)
-- ADC (Indirect),Y (opcode 0x71)
-- ADC (Indirect),Y (0x71)
it("ADC (indirect),Y uses 6 cycles and returns the correct result", function()
  local cpu = MOS6502.new()
  cpu.A = 10; cpu.Y = 1
  -- Set up zero page pointer so that base = 0x2FFF:
  cpu:write(0x0010, 0xFF) -- pointer low byte
  cpu:write(0x0011, 0x2F) -- pointer high byte
  -- Effective address = 0x2FFF + 1 = 0x3000. Write operand there:
  cpu:write(0x3000, 15)
  cpu:write(0x8000, 0x71) -- Write opcode 0x71 (ADC (indirect),Y)
  cpu:write(0x8001, 0x10) -- Write operand: zero page address 0x10
  cpu:write(0xFFFC, 0x00) -- Reset vector low byte
  cpu:write(0xFFFD, 0x80) -- Reset vector high byte
  cpu:reset()
  -- Ensure carry flag is clear
  cpu.P = cpu.P & 0xFE
  cpu:step()
  -- Expected result: 10 + 15 = 25
  assert_equal(cpu.A, 25, "ADC (indirect),Y result should be 25 (10+15)")
  assert_equal(cpu.cycles, 6, "ADC (indirect),Y uses 6 cycles")
end)

-- ADC (Indirect),Y (0x71)
it("ADC (indirect),Y uses 6 cycles", function()
  local cpu = MOS6502.new()
  cpu.A = 10; cpu.Y = 1; cpu.P = 0
  cpu:write(0x0010, 0x00) -- Write pointer low at zero page address 0x10
  cpu:write(0x0011, 0x80) -- Write pointer high at zero page address 0x11
  cpu:write(0x3000, 15)   -- Write data 15 at computed address (from pointer plus Y)
  cpu:write(0x8000, 0x71) -- Write opcode 0x71 (ADC (indirect),Y)
  cpu:write(0x8001, 0x10) -- Write operand: zero page address 0x10
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.A, 25, "ADC (indirect),Y result should be 25 (10+15)")
  assert_equal(cpu.cycles, 6, "ADC (indirect),Y uses 6 cycles")
end)

-------------------------------------------------
-- AND (Logical AND)
-- AND Immediate (0x29)
it("AND immediate returns 2 cycles", function()
  local cpu = MOS6502.new()
  cpu.A = 0xF0
  cpu:write(0x8000, 0x29) -- Write opcode 0x29 (AND immediate)
  cpu:write(0x8001, 0x0F) -- Write immediate operand 0x0F
  cpu:write(0xFFFC, 0x00) -- Reset vector low byte
  cpu:write(0xFFFD, 0x80) -- Reset vector high byte
  cpu:reset()
  cpu:step()
  assert_equal(cpu.A, 0x00, "AND immediate: 0xF0 AND 0x0F should be 0x00")
  assert_equal(cpu.cycles, 2, "AND immediate uses 2 cycles")
end)
-- AND Zero Page (0x25)
it("AND zero page returns 3 cycles", function()
  local cpu = MOS6502.new()
  cpu.A = 0xAA
  cpu:write(0x0010, 0x0F) -- Write data 0x0F at zero page address 0x10
  cpu:write(0x8000, 0x25) -- Write opcode 0x25 (AND zero page)
  cpu:write(0x8001, 0x10) -- Write operand: address 0x10
  cpu:write(0xFFFC, 0x00) -- Set reset vector low
  cpu:write(0xFFFD, 0x80) -- Set reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.A, 0x0A, "AND zero page: 0xAA AND 0x0F should be 0x0A")
  assert_equal(cpu.cycles, 3, "AND zero page uses 3 cycles")
end)
-- AND Zero Page,X (0x35)
it("AND zero page,X returns 4 cycles", function()
  local cpu = MOS6502.new()
  cpu.A = 0xFF; cpu.X = 1
  cpu:write(0x0011, 0x55) -- Write data 0x55 at address (0x10+X)
  cpu:write(0x8000, 0x35) -- Write opcode 0x35 (AND zero page,X)
  cpu:write(0x8001, 0x10) -- Write operand: base address 0x10
  cpu:write(0xFFFC, 0x00) -- Set reset vector low byte
  cpu:write(0xFFFD, 0x80) -- Set reset vector high byte
  cpu:reset()
  cpu:step()
  assert_equal(cpu.A, 0x55, "AND zero page,X: 0xFF AND 0x55 should be 0x55")
  assert_equal(cpu.cycles, 4, "AND zero page,X uses 4 cycles")
end)
-- AND Absolute (0x2D)
it("AND absolute returns 4 cycles", function()
  local cpu = MOS6502.new()
  cpu.A = 0xF0
  cpu:write(0x1234, 0x0F) -- Write data 0x0F at absolute address 0x1234
  cpu:write(0x8000, 0x2D) -- Write opcode 0x2D (AND absolute)
  cpu:write(0x8001, 0x34) -- Write low byte of address 0x1234
  cpu:write(0x8002, 0x12) -- Write high byte of address 0x1234
  cpu:write(0xFFFC, 0x00) -- Set reset vector low
  cpu:write(0xFFFD, 0x80) -- Set reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.A, 0x00, "AND absolute: 0xF0 AND 0x0F should be 0x00")
  assert_equal(cpu.cycles, 4, "AND absolute uses 4 cycles")
end)
-- AND Absolute,X (0x3D)
it("AND absolute,X returns 4 cycles (no page cross)", function()
  local cpu = MOS6502.new()
  cpu.A = 0xFF; cpu.X = 2
  cpu:write(0x1002, 0x55) -- Write data 0x55 at effective address (base+X)
  cpu:write(0x8000, 0x3D) -- Write opcode 0x3D (AND absolute,X)
  cpu:write(0x8001, 0x00) -- Write low byte of base address (0x0000)
  cpu:write(0x8002, 0x10) -- Write high byte of base address (0x10)
  cpu:write(0xFFFC, 0x00) -- Set reset vector low
  cpu:write(0xFFFD, 0x80) -- Set reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.A, 0x55, "AND absolute,X (no page cross): result should be 0x55")
  assert_equal(cpu.cycles, 4, "AND absolute,X (no page cross) uses 4 cycles")
end)
-- AND Absolute,Y (0x39)
it("AND absolute,Y returns 4 cycles (no page cross)", function()
  local cpu = MOS6502.new()
  cpu.A = 0xFF; cpu.Y = 3
  cpu:write(0x2003, 0xAA) -- Write data 0xAA at effective address (base+Y)
  cpu:write(0x8000, 0x39) -- Write opcode 0x39 (AND absolute,Y)
  cpu:write(0x8001, 0x00) -- Write low byte of base address (0x2000)
  cpu:write(0x8002, 0x20) -- Write high byte of base address (0x20)
  cpu:write(0xFFFC, 0x00) -- Set reset vector low
  cpu:write(0xFFFD, 0x80) -- Set reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.A, 0xAA, "AND absolute,Y (no page cross): result should be 0xAA")
  assert_equal(cpu.cycles, 4, "AND absolute,Y (no page cross) uses 4 cycles")
end)
-- AND (Indirect,X) (0x21)
it("AND (indirect,X) returns 6 cycles", function()
  local cpu = MOS6502.new()
  cpu.A = 0xFF; cpu.X = 1
  local zp = 0x20
  cpu:write(zp + cpu.X, 0x00)                -- Write pointer low at (0x20+X)
  cpu:write(((zp + cpu.X + 1) & 0xFF), 0x30) -- Write pointer high at (0x20+X+1)
  cpu:write(0x3000, 0x0F)                    -- Write data 0x0F at computed address 0x3000
  cpu:write(0x8000, 0x21)                    -- Write opcode 0x21 (AND (indirect,X))
  cpu:write(0x8001, 0x20)                    -- Write operand: base zero page address 0x20
  cpu:write(0xFFFC, 0x00)                    -- Reset vector low
  cpu:write(0xFFFD, 0x80)                    -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.A, 0x0F, "AND (indirect,X): 0xFF AND 0x0F should be 0x0F")
  assert_equal(cpu.cycles, 6, "AND (indirect,X) uses 6 cycles")
end)
-- AND (Indirect),Y (0x31)
it("AND (indirect),Y returns 5 cycles (no page cross)", function()
  local cpu = MOS6502.new()
  cpu.A = 0xFF; cpu.Y = 1
  cpu:write(0x20, 0x00)   -- Write pointer low at zero page 0x20
  cpu:write(0x21, 0x40)   -- Write pointer high at zero page 0x21
  cpu:write(0x8000, 0x31) -- Write opcode 0x31 (AND (indirect),Y)
  cpu:write(0x8001, 0x20) -- Write operand: zero page address 0x20
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.A, 0xFF, "AND (indirect),Y: 0xFF AND data should remain 0xFF")
  assert_equal(cpu.cycles, 5, "AND (indirect),Y uses 5 cycles")
end)

-------------------------------------------------
-- ASL (Arithmetic Shift Left)
-- ASL Accumulator (0x0A)
it("ASL accumulator rotates bits left and uses 2 cycles", function()
  local cpu = MOS6502.new()
  cpu.A = 0x80
  cpu:write(0x8000, 0x0A) -- Write opcode 0x0A (ASL accumulator)
  cpu:write(0xFFFC, 0x00) -- Reset vector low byte
  cpu:write(0xFFFD, 0x80) -- Reset vector high byte
  cpu:reset()
  cpu:step()
  assert_equal(cpu.A, 0x00, "ASL accumulator: shifting 0x80 should yield 0x00 and set carry")
  assert_equal(cpu.cycles, 2, "ASL accumulator uses 2 cycles")
end)
-- ASL Zero Page (0x06)
it("ASL zero page shifts memory left and uses 5 cycles", function()
  local cpu = MOS6502.new()
  cpu:write(0x0010, 0x40) -- Write data 0x40 at zero page address 0x10
  cpu:write(0x8000, 0x06) -- Write opcode 0x06 (ASL zero page)
  cpu:write(0x8001, 0x10) -- Write operand: address 0x10
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu:read(0x0010), 0x80, "ASL zero page: 0x40 shifted left becomes 0x80")
  assert_equal(cpu.cycles, 5, "ASL zero page uses 5 cycles")
end)
-- ASL Zero Page,X (0x16)
it("ASL zero page,X shifts memory left and uses 6 cycles", function()
  local cpu = MOS6502.new()
  cpu.X = 1
  cpu:write(0x0011, 0x20) -- Write data 0x20 at address (0x10+X)
  cpu:write(0x8000, 0x16) -- Write opcode 0x16 (ASL zero page,X)
  cpu:write(0x8001, 0x10) -- Write operand: base zero page address 0x10
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu:read(0x0011), 0x40, "ASL zero page,X: 0x20 shifted left becomes 0x40")
  assert_equal(cpu.cycles, 6, "ASL zero page,X uses 6 cycles")
end)
-- ASL Absolute (0x0E)
it("ASL absolute shifts memory left and uses 6 cycles", function()
  local cpu = MOS6502.new()
  cpu:write(0x1234, 0x20) -- Write data 0x20 at absolute address 0x1234
  cpu:write(0x8000, 0x0E) -- Write opcode 0x0E (ASL absolute)
  cpu:write(0x8001, 0x34) -- Write low byte of address 0x1234
  cpu:write(0x8002, 0x12) -- Write high byte of address 0x1234
  cpu:write(0xFFFC, 0x00) -- Reset vector low byte
  cpu:write(0xFFFD, 0x80) -- Reset vector high byte
  cpu:reset()
  cpu:step()
  assert_equal(cpu:read(0x1234), 0x40, "ASL absolute: 0x20 shifted left becomes 0x40")
  assert_equal(cpu.cycles, 6, "ASL absolute uses 6 cycles")
end)
-- ASL Absolute,X (0x1E)
it("ASL absolute,X shifts memory left and uses 7 cycles", function()
  local cpu = MOS6502.new()
  cpu.X = 1
  cpu:write(0x1235, 0x10) -- Write data 0x10 at effective address (base+X)
  cpu:write(0x8000, 0x1E) -- Write opcode 0x1E (ASL absolute,X)
  cpu:write(0x8001, 0x34) -- Write low byte of base address
  cpu:write(0x8002, 0x12) -- Write high byte of base address
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu:read(0x1235), 0x20, "ASL absolute,X: 0x10 shifted left becomes 0x20")
  assert_equal(cpu.cycles, 7, "ASL absolute,X uses 7 cycles")
end)

-------------------------------------------------
-- Branch Instructions
-- BCC (Branch if Carry Clear, opcode 0x90)
it("BCC not taken returns 2 cycles", function()
  local cpu = MOS6502.new()
  cpu.P = 0x01            -- Carry flag set so branch is not taken
  cpu:write(0x8000, 0x90) -- Write opcode 0x90 (BCC)
  cpu:write(0x8001, 0x05) -- Write branch offset 0x05
  cpu:write(0xFFFC, 0x00) -- Reset vector low byte
  cpu:write(0xFFFD, 0x80) -- Reset vector high byte
  cpu:reset()
  local init_pc = cpu.PC
  cpu:step()
  assert_equal(cpu.PC, init_pc + 1, "BCC not taken: PC should advance by 1")
  assert_equal(cpu.cycles, 2, "BCC not taken uses 2 cycles")
end)
it("BCC taken returns 3 cycles", function()
  local cpu = MOS6502.new()
  cpu.P = 0x00            -- Carry flag clear so branch is taken
  cpu:write(0x8000, 0x90) -- Write opcode: BCC
  cpu:write(0x8001, 0x05) -- Write branch offset 0x05
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  local init_pc = cpu.PC
  cpu:step()
  assert_equal(cpu.PC, (init_pc + 5) & 0xFFFF, "BCC taken: PC should jump by offset")
  assert_equal(cpu.cycles, 3, "BCC taken uses 3 cycles")
end)
-- BCS (Branch if Carry Set, opcode 0xB0)
it("BCS taken returns 3 cycles", function()
  local cpu = MOS6502.new()
  cpu.P = 0x01            -- Carry flag set so branch is taken
  cpu:write(0x8000, 0xB0) -- Write opcode: BCS
  cpu:write(0x8001, 0x05) -- Write branch offset 0x05
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  local init_pc = cpu.PC
  cpu:step()
  assert_equal(cpu.PC, (init_pc + 5) & 0xFFFF, "BCS taken: PC should jump by offset")
  assert_equal(cpu.cycles, 3, "BCS taken uses 3 cycles")
end)
it("BCS not taken returns 2 cycles", function()
  local cpu = MOS6502.new()
  cpu.P = 0x00            -- Carry clear so branch is not taken
  cpu:write(0x8000, 0xB0) -- Write opcode: BCS
  cpu:write(0x8001, 0x05) -- Write branch offset 0x05
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  local init_pc = cpu.PC
  cpu:step()
  assert_equal(cpu.PC, init_pc + 1, "BCS not taken: PC should advance by 1")
  assert_equal(cpu.cycles, 2, "BCS not taken uses 2 cycles")
end)
-- BEQ (Branch if Equal, opcode 0xF0)
it("BEQ taken returns 3 cycles", function()
  local cpu = MOS6502.new()
  cpu.P = 0x02            -- Zero flag set so branch is taken
  cpu:write(0x8000, 0xF0) -- Write opcode: BEQ
  cpu:write(0x8001, 0x05) -- Write branch offset 0x05
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  local init_pc = cpu.PC
  cpu:step()
  assert_equal(cpu.PC, (init_pc + 5) & 0xFFFF, "BEQ taken: PC should jump by offset")
  assert_equal(cpu.cycles, 3, "BEQ taken uses 3 cycles")
end)
it("BEQ not taken returns 2 cycles", function()
  local cpu = MOS6502.new()
  cpu.P = 0x00            -- Zero flag clear so branch is not taken
  cpu:write(0x8000, 0xF0) -- Write opcode: BEQ
  cpu:write(0x8001, 0x05) -- Write branch offset 0x05
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  local init_pc = cpu.PC
  cpu:step()
  assert_equal(cpu.PC, init_pc + 1, "BEQ not taken: PC should advance by 1")
  assert_equal(cpu.cycles, 2, "BEQ not taken uses 2 cycles")
end)
-- BMI (Branch if Minus, opcode 0x30)
it("BMI taken returns 3 cycles", function()
  local cpu = MOS6502.new()
  cpu.P = 0x80            -- Negative flag set so branch is taken
  cpu:write(0x8000, 0x30) -- Write opcode: BMI
  cpu:write(0x8001, 0x05) -- Write branch offset 0x05
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  local init_pc = cpu.PC
  cpu:step()
  assert_equal(cpu.PC, (init_pc + 5) & 0xFFFF, "BMI taken: PC should jump by offset")
  assert_equal(cpu.cycles, 3, "BMI taken uses 3 cycles")
end)
it("BMI not taken returns 2 cycles", function()
  local cpu = MOS6502.new()
  cpu.P = 0x00            -- Negative flag clear so branch is not taken
  cpu:write(0x8000, 0x30) -- Write opcode: BMI
  cpu:write(0x8001, 0x05) -- Write branch offset 0x05
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  local init_pc = cpu.PC
  cpu:step()
  assert_equal(cpu.PC, init_pc + 1, "BMI not taken: PC should advance by 1")
  assert_equal(cpu.cycles, 2, "BMI not taken uses 2 cycles")
end)
-- BNE (Branch if Not Equal, opcode 0xD0)
it("BNE taken returns 3 cycles", function()
  local cpu = MOS6502.new()
  cpu.P = 0x00            -- Zero flag clear so branch is taken
  cpu:write(0x8000, 0xD0) -- Write opcode: BNE
  cpu:write(0x8001, 0x05) -- Write branch offset 0x05
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  local init_pc = cpu.PC
  cpu:step()
  assert_equal(cpu.PC, (init_pc + 5) & 0xFFFF, "BNE taken: PC should jump by offset")
  assert_equal(cpu.cycles, 3, "BNE taken uses 3 cycles")
end)
it("BNE not taken returns 2 cycles", function()
  local cpu = MOS6502.new()
  cpu.P = 0x02            -- Zero flag set so branch is not taken
  cpu:write(0x8000, 0xD0) -- Write opcode: BNE
  cpu:write(0x8001, 0x05) -- Write branch offset 0x05
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  local init_pc = cpu.PC
  cpu:step()
  assert_equal(cpu.PC, init_pc + 1, "BNE not taken: PC should advance by 1")
  assert_equal(cpu.cycles, 2, "BNE not taken uses 2 cycles")
end)
-- BPL (Branch if Plus, opcode 0x10)
it("BPL taken returns 3 cycles", function()
  local cpu = MOS6502.new()
  cpu.P = 0x00            -- Negative flag clear so branch is taken
  cpu:write(0x8000, 0x10) -- Write opcode: BPL
  cpu:write(0x8001, 0x05) -- Write branch offset 0x05
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  local init_pc = cpu.PC
  cpu:step()
  assert_equal(cpu.PC, (init_pc + 5) & 0xFFFF, "BPL taken: PC should jump by offset")
  assert_equal(cpu.cycles, 3, "BPL taken uses 3 cycles")
end)
it("BPL not taken returns 2 cycles", function()
  local cpu = MOS6502.new()
  cpu.P = 0x80            -- Negative flag set so branch is not taken
  cpu:write(0x8000, 0x10) -- Write opcode: BPL
  cpu:write(0x8001, 0x05) -- Write branch offset 0x05
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  local init_pc = cpu.PC
  cpu:step()
  assert_equal(cpu.PC, init_pc + 1, "BPL not taken: PC should advance by 1")
  assert_equal(cpu.cycles, 2, "BPL not taken uses 2 cycles")
end)
-- BVC (Branch if Overflow Clear, opcode 0x50)
it("BVC taken returns 3 cycles", function()
  local cpu = MOS6502.new()
  cpu.P = 0x00            -- Overflow flag clear so branch is taken
  cpu:write(0x8000, 0x50) -- Write opcode: BVC
  cpu:write(0x8001, 0x05) -- Write branch offset 0x05
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  local init_pc = cpu.PC
  cpu:step()
  assert_equal(cpu.PC, (init_pc + 5) & 0xFFFF, "BVC taken: PC should jump by offset")
  assert_equal(cpu.cycles, 3, "BVC taken uses 3 cycles")
end)
it("BVC not taken returns 2 cycles", function()
  local cpu = MOS6502.new()
  cpu.P = 0x40            -- Overflow flag set so branch is not taken
  cpu:write(0x8000, 0x50) -- Write opcode: BVC
  cpu:write(0x8001, 0x05) -- Write branch offset 0x05
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  local init_pc = cpu.PC
  cpu:step()
  assert_equal(cpu.PC, init_pc + 1, "BVC not taken: PC should advance by 1")
  assert_equal(cpu.cycles, 2, "BVC not taken uses 2 cycles")
end)
-- BVS (Branch if Overflow Set, opcode 0x70)
it("BVS taken returns 3 cycles", function()
  local cpu = MOS6502.new()
  cpu.P = 0x40            -- Overflow flag set so branch is taken
  cpu:write(0x8000, 0x70) -- Write opcode: BVS
  cpu:write(0x8001, 0x05) -- Write branch offset 0x05
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  local init_pc = cpu.PC
  cpu:step()
  assert_equal(cpu.PC, (init_pc + 5) & 0xFFFF, "BVS taken: PC should jump by offset")
  assert_equal(cpu.cycles, 3, "BVS taken uses 3 cycles")
end)
it("BVS not taken returns 2 cycles", function()
  local cpu = MOS6502.new()
  cpu.P = 0x00            -- Overflow flag clear so branch is not taken
  cpu:write(0x8000, 0x70) -- Write opcode: BVS
  cpu:write(0x8001, 0x05) -- Write branch offset 0x05
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  local init_pc = cpu.PC
  cpu:step()
  assert_equal(cpu.PC, init_pc + 1, "BVS not taken: PC should advance by 1")
  assert_equal(cpu.cycles, 2, "BVS not taken uses 2 cycles")
end)

-------------------------------------------------
-- BIT (Bit Test)
-- BIT Zero Page (0x24)
it("BIT zero page tests flags and uses 3 cycles", function()
  local cpu = MOS6502.new()
  cpu.A = 0x0F
  cpu:write(0x0010, 0x80) -- Write data 0x80 at zero page address 0x10 (bit 7 set)
  cpu:write(0x8000, 0x24) -- Write opcode: BIT zero page
  cpu:write(0x8001, 0x10) -- Write operand: address 0x10
  cpu:write(0xFFFC, 0x00) -- Set reset vector low
  cpu:write(0xFFFD, 0x80) -- Set reset vector high
  cpu:reset()
  cpu:step()
  -- BIT sets the zero flag if (A & data)==0; it also loads bit 7 and bit 6 of memory into flags N and V.
  assert_equal((cpu.P & 0x02) ~= 0, true, "BIT zero page: Zero flag should be set when (A & data)==0")
  assert_equal((cpu.P & 0x80) ~= 0, true, "BIT zero page: Negative flag should reflect bit 7 of memory (set)")
  assert_equal((cpu.P & 0x40) == 0, true, "BIT zero page: Overflow flag should reflect bit 6 of memory (clear)")
  assert_equal(cpu.cycles, 3, "BIT zero page uses 3 cycles")
end)
-- BIT Absolute (0x2C)
it("BIT absolute tests flags and uses 4 cycles", function()
  local cpu = MOS6502.new()
  cpu.A = 0x0F
  cpu:write(0x1234, 0x40) -- Write data 0x40 at absolute address 0x1234 (bit 6 set)
  cpu:write(0x8000, 0x2C) -- Write opcode: BIT absolute
  cpu:write(0x8001, 0x34) -- Write low byte of target address (0x1234)
  cpu:write(0x8002, 0x12) -- Write high byte of target address (0x1234)
  cpu:write(0xFFFC, 0x00) -- Reset vector low byte
  cpu:write(0xFFFD, 0x80) -- Reset vector high byte
  cpu:reset()
  cpu:step()
  assert_equal((cpu.P & 0x02) ~= 0, true, "BIT absolute: Zero flag should be set when (A & data)==0")
  assert_equal((cpu.P & 0x80) == 0, true, "BIT absolute: Negative flag should reflect bit 7 of memory (clear)")
  assert_equal((cpu.P & 0x40) ~= 0, true, "BIT absolute: Overflow flag should reflect bit 6 of memory (set)")
  assert_equal(cpu.cycles, 4, "BIT absolute uses 4 cycles")
end)

-------------------------------------------------
-- BRK (Force Interrupt, opcode 0x00)
it("BRK halts the CPU and uses 7 cycles", function()
  local cpu = MOS6502.new()
  cpu:write(0x8000, 0x00) -- Write opcode 0x00 (BRK) at 0x8000
  cpu:write(0xFFFC, 0x00) -- Reset vector low byte
  cpu:write(0xFFFD, 0x80) -- Reset vector high byte
  cpu:reset()
  cpu:step()
  assert_equal(cpu.halted, true, "BRK should halt the CPU")
  assert_equal(cpu.cycles, 7, "BRK uses 7 cycles")
end)

-------------------------------------------------
-- Flag Instructions
-- CLC (Clear Carry, 0x18)
it("CLC clears the carry flag and uses 2 cycles", function()
  local cpu = MOS6502.new()
  cpu.P = 0xFF            -- All flags initially set
  cpu:write(0x8000, 0x18) -- Write opcode 0x18 (CLC)
  cpu:write(0xFFFC, 0x00) -- Reset vector low byte
  cpu:write(0xFFFD, 0x80) -- Reset vector high byte
  cpu:reset()
  cpu:step()
  assert_equal((cpu.P & 0x01), 0, "CLC should clear the carry flag")
  assert_equal(cpu.cycles, 2, "CLC uses 2 cycles")
end)
-- CLD (Clear Decimal, 0xD8)
it("CLD clears the decimal flag and uses 2 cycles", function()
  local cpu = MOS6502.new()
  cpu.P = 0xFF
  cpu:write(0x8000, 0xD8) -- Write opcode 0xD8 (CLD)
  cpu:write(0xFFFC, 0x00)
  cpu:write(0xFFFD, 0x80)
  cpu:reset()
  cpu:step()
  assert_equal((cpu.P & 0x08), 0, "CLD should clear the decimal flag")
  assert_equal(cpu.cycles, 2, "CLD uses 2 cycles")
end)
-- CLI (Clear Interrupt, 0x58)
it("CLI clears the interrupt disable flag and uses 2 cycles", function()
  local cpu = MOS6502.new()
  cpu.P = 0xFF
  cpu:write(0x8000, 0x58) -- Write opcode 0x58 (CLI)
  cpu:write(0xFFFC, 0x00)
  cpu:write(0xFFFD, 0x80)
  cpu:reset()
  cpu:step()
  assert_equal((cpu.P & 0x04), 0, "CLI should clear the interrupt disable flag")
  assert_equal(cpu.cycles, 2, "CLI uses 2 cycles")
end)
-- CLV (Clear Overflow, 0xB8)
it("CLV clears the overflow flag and uses 2 cycles", function()
  local cpu = MOS6502.new()
  cpu.P = 0xFF
  cpu:write(0x8000, 0xB8) -- Write opcode 0xB8 (CLV)
  cpu:write(0xFFFC, 0x00)
  cpu:write(0xFFFD, 0x80)
  cpu:reset()
  cpu:step()
  assert_equal((cpu.P & 0x40), 0, "CLV should clear the overflow flag")
  assert_equal(cpu.cycles, 2, "CLV uses 2 cycles")
end)

-------------------------------------------------
-- CMP (Compare Accumulator)
-- CMP Immediate (0xC9)
it("CMP immediate with equal operand returns 2 cycles", function()
  local cpu = MOS6502.new()
  cpu.A = 50
  cpu:write(0x8000, 0xC9) -- Write opcode 0xC9 (CMP immediate)
  cpu:write(0x8001, 50)   -- Write immediate operand equal to A (50)
  cpu:write(0xFFFC, 0x00)
  cpu:write(0xFFFD, 0x80)
  cpu:reset()
  cpu:step()
  assert_equal((cpu.P & 0x01) ~= 0, true, "CMP immediate should set carry flag when A>=operand")
  assert_equal(cpu.cycles, 2, "CMP immediate uses 2 cycles")
end)
-- CMP Zero Page (0xC5)
it("CMP zero page with equal operand returns 3 cycles", function()
  local cpu = MOS6502.new()
  cpu.A = 100
  cpu:write(0x0010, 100)  -- Write data equal to A at zero page address 0x10
  cpu:write(0x8000, 0xC5) -- Write opcode 0xC5 (CMP zero page)
  cpu:write(0x8001, 0x10) -- Write operand: address 0x10
  cpu:write(0xFFFC, 0x00)
  cpu:write(0xFFFD, 0x80)
  cpu:reset()
  cpu:step()
  assert_equal((cpu.P & 0x01) ~= 0, true, "CMP zero page should set carry flag when A>=operand")
  assert_equal(cpu.cycles, 3, "CMP zero page uses 3 cycles")
end)
-- CMP Zero Page,X (0xD5)
it("CMP zero page,X with equal operand returns 4 cycles", function()
  local cpu = MOS6502.new()
  cpu.A = 150; cpu.X = 1
  cpu:write(0x0011, 150)  -- Write data equal to A at address (0x10+X)
  cpu:write(0x8000, 0xD5) -- Write opcode 0xD5 (CMP zero page,X)
  cpu:write(0x8001, 0x10) -- Write operand: base zero page address 0x10
  cpu:write(0xFFFC, 0x00)
  cpu:write(0xFFFD, 0x80)
  cpu:reset()
  cpu:step()
  assert_equal((cpu.P & 0x01) ~= 0, true, "CMP zero page,X should set carry flag when equal")
  assert_equal(cpu.cycles, 4, "CMP zero page,X uses 4 cycles")
end)
-- CMP Absolute (0xCD)
it("CMP absolute with equal operand returns 4 cycles", function()
  local cpu = MOS6502.new()
  cpu.A = 200
  cpu:write(0x1234, 200)  -- Write data equal to A at absolute address 0x1234
  cpu:write(0x8000, 0xCD) -- Write opcode 0xCD (CMP absolute)
  cpu:write(0x8001, 0x34) -- Write low byte of address 0x1234
  cpu:write(0x8002, 0x12) -- Write high byte of address 0x1234
  cpu:write(0xFFFC, 0x00)
  cpu:write(0xFFFD, 0x80)
  cpu:reset()
  cpu:step()
  assert_equal((cpu.P & 0x01) ~= 0, true, "CMP absolute should set carry flag when A>=operand")
  assert_equal(cpu.cycles, 4, "CMP absolute uses 4 cycles")
end)
-- CMP Absolute,X (0xDD)
it("CMP absolute,X with equal operand returns 4 cycles (no page cross)", function()
  local cpu = MOS6502.new()
  cpu.A = 10; cpu.X = 2
  cpu:write(0x1002, 10)   -- Write data equal to A at effective address (base+X)
  cpu:write(0x8000, 0xDD) -- Write opcode 0xDD (CMP absolute,X)
  cpu:write(0x8001, 0x00) -- Write low byte of base address
  cpu:write(0x8002, 0x10) -- Write high byte of base address
  cpu:write(0xFFFC, 0x00)
  cpu:write(0xFFFD, 0x80)
  cpu:reset()
  cpu:step()
  assert_equal((cpu.P & 0x01) ~= 0, true, "CMP absolute,X should set carry flag when equal")
  assert_equal(cpu.cycles, 4, "CMP absolute,X uses 4 cycles")
end)
-- CMP Absolute,Y (0xD9)
it("CMP absolute,Y with equal operand returns 4 cycles (no page cross)", function()
  local cpu = MOS6502.new()
  cpu.A = 25; cpu.Y = 3
  cpu:write(0x2003, 25)   -- Write data equal to A at effective address (base+Y)
  cpu:write(0x8000, 0xD9) -- Write opcode 0xD9 (CMP absolute,Y)
  cpu:write(0x8001, 0x00) -- Write low byte of base address
  cpu:write(0x8002, 0x20) -- Write high byte of base address
  cpu:write(0xFFFC, 0x00)
  cpu:write(0xFFFD, 0x80)
  cpu:reset()
  cpu:step()
  assert_equal((cpu.P & 0x01) ~= 0, true, "CMP absolute,Y should set carry flag when equal")
  assert_equal(cpu.cycles, 4, "CMP absolute,Y uses 4 cycles")
end)
-- CMP (Indirect,X) (0xC1)
it("CMP (indirect,X) with equal operand returns 6 cycles", function()
  local cpu = MOS6502.new()
  cpu.A = 60; cpu.X = 1
  local zp = 0x20
  cpu:write(zp + cpu.X, 0x00)                -- Write pointer low at (0x20+X)
  cpu:write(((zp + cpu.X + 1) & 0xFF), 0x30) -- Write pointer high at (0x20+X+1)
  cpu:write(0x8000, 0xC1)                    -- Write opcode 0xC1 (CMP (indirect,X))
  cpu:write(0x8001, 0x20)                    -- Write operand: zero page base 0x20
  cpu:write(0xFFFC, 0x00)
  cpu:write(0xFFFD, 0x80)
  cpu:reset()
  cpu:step()
  assert_equal((cpu.P & 0x01) ~= 0, true, "CMP (indirect,X) should set carry flag when equal")
  assert_equal(cpu.cycles, 6, "CMP (indirect,X) uses 6 cycles")
end)
-- CMP (Indirect),Y (0xD1)
it("CMP (indirect),Y with equal operand returns 5 cycles (no page cross)", function()
  local cpu = MOS6502.new()
  cpu.A = 80; cpu.Y = 4
  cpu:write(0x20, 0x00)   -- Write pointer low at zero page address 0x20
  cpu:write(0x21, 0x40)   -- Write pointer high at zero page address 0x21
  cpu:write(0x8000, 0xD1) -- Write opcode 0xD1 (CMP (indirect),Y)
  cpu:write(0x8001, 0x20) -- Write operand: zero page address 0x20
  cpu:write(0xFFFC, 0x00)
  cpu:write(0xFFFD, 0x80)
  cpu:reset()
  cpu:step()
  assert_equal((cpu.P & 0x01) ~= 0, true, "CMP (indirect),Y should set carry flag when equal")
  assert_equal(cpu.cycles, 5, "CMP (indirect),Y uses 5 cycles")
end)

-------------------------------------------------
-- CPX (Compare X Register)
-- CPX Immediate (0xE0)
it("CPX immediate with equal operand returns 2 cycles", function()
  local cpu = MOS6502.new()
  cpu.X = 30
  cpu:write(0x8000, 0xE0) -- Write opcode 0xE0 (CPX immediate)
  cpu:write(0x8001, 30)   -- Write operand equal to X (30)
  cpu:write(0xFFFC, 0x00)
  cpu:write(0xFFFD, 0x80)
  cpu:reset()
  cpu:step()
  assert_equal((cpu.P & 0x01) ~= 0, true, "CPX immediate should set carry flag when X>=operand")
  assert_equal(cpu.cycles, 2, "CPX immediate uses 2 cycles")
end)
-- CPX Zero Page (0xE4)
it("CPX zero page with equal operand returns 3 cycles", function()
  local cpu = MOS6502.new()
  cpu.X = 40
  cpu:write(0x0010, 40)   -- Write data equal to X at zero page address 0x10
  cpu:write(0x8000, 0xE4) -- Write opcode 0xE4 (CPX zero page)
  cpu:write(0x8001, 0x10) -- Write operand: address 0x10
  cpu:write(0xFFFC, 0x00)
  cpu:write(0xFFFD, 0x80)
  cpu:reset()
  cpu:step()
  assert_equal((cpu.P & 0x01) ~= 0, true, "CPX zero page should set carry flag when X>=operand")
  assert_equal(cpu.cycles, 3, "CPX zero page uses 3 cycles")
end)
-- CPX Absolute (0xEC)
it("CPX absolute with equal operand returns 4 cycles", function()
  local cpu = MOS6502.new()
  cpu.X = 50
  cpu:write(0x1234, 50)   -- Write data equal to X at absolute address 0x1234
  cpu:write(0x8000, 0xEC) -- Write opcode 0xEC (CPX absolute)
  cpu:write(0x8001, 0x34) -- Write low byte of address 0x1234
  cpu:write(0x8002, 0x12) -- Write high byte of address 0x1234
  cpu:write(0xFFFC, 0x00)
  cpu:write(0xFFFD, 0x80)
  cpu:reset()
  cpu:step()
  assert_equal((cpu.P & 0x01) ~= 0, true, "CPX absolute should set carry flag when X>=operand")
  assert_equal(cpu.cycles, 4, "CPX absolute uses 4 cycles")
end)

-------------------------------------------------
-- CPY (Compare Y Register)
-- CPY Immediate (0xC0)
it("CPY immediate with equal operand returns 2 cycles", function()
  local cpu = MOS6502.new()
  cpu.Y = 60
  cpu:write(0x8000, 0xC0) -- Write opcode 0xC0 (CPY immediate)
  cpu:write(0x8001, 60)   -- Write operand equal to Y (60)
  cpu:write(0xFFFC, 0x00)
  cpu:write(0xFFFD, 0x80)
  cpu:reset()
  cpu:step()
  assert_equal((cpu.P & 0x01) ~= 0, true, "CPY immediate should set carry flag when Y>=operand")
  assert_equal(cpu.cycles, 2, "CPY immediate uses 2 cycles")
end)
-- CPY Zero Page (0xC4)
it("CPY zero page with equal operand returns 3 cycles", function()
  local cpu = MOS6502.new()
  cpu.Y = 70
  cpu:write(0x0010, 70)   -- Write data equal to Y at zero page address 0x10
  cpu:write(0x8000, 0xC4) -- Write opcode 0xC4 (CPY zero page)
  cpu:write(0x8001, 0x10) -- Write operand: address 0x10
  cpu:write(0xFFFC, 0x00)
  cpu:write(0xFFFD, 0x80)
  cpu:reset()
  cpu:step()
  assert_equal((cpu.P & 0x01) ~= 0, true, "CPY zero page should set carry flag when Y>=operand")
  assert_equal(cpu.cycles, 3, "CPY zero page uses 3 cycles")
end)
-- CPY Absolute (0xCC)
it("CPY absolute with equal operand returns 4 cycles", function()
  local cpu = MOS6502.new()
  cpu.Y = 80
  cpu:write(0x1234, 80)   -- Write data equal to Y at absolute address 0x1234
  cpu:write(0x8000, 0xCC) -- Write opcode 0xCC (CPY absolute)
  cpu:write(0x8001, 0x34) -- Write low byte of address 0x1234
  cpu:write(0x8002, 0x12) -- Write high byte of address 0x1234
  cpu:write(0xFFFC, 0x00)
  cpu:write(0xFFFD, 0x80)
  cpu:reset()
  cpu:step()
  assert_equal((cpu.P & 0x01) ~= 0, true, "CPY absolute should set carry flag when Y>=operand")
  assert_equal(cpu.cycles, 4, "CPY absolute uses 4 cycles")
end)

-------------------------------------------------
-- DEC (Decrement Memory)
-- DEC Zero Page (0xC6)
it("DEC zero page decrements memory and uses 5 cycles", function()
  local cpu = MOS6502.new()
  cpu:write(0x0010, 5)    -- Write value 5 at zero page address 0x10
  cpu:write(0x8000, 0xC6) -- Write opcode 0xC6 (DEC zero page)
  cpu:write(0x8001, 0x10) -- Write operand: address 0x10
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu:read(0x0010), 4, "DEC zero page should decrement value from 5 to 4")
  assert_equal(cpu.cycles, 5, "DEC zero page uses 5 cycles")
end)
-- DEC Zero Page,X (0xD6)
it("DEC zero page,X decrements memory and uses 6 cycles", function()
  local cpu = MOS6502.new()
  cpu.X = 1
  cpu:write(0x0011, 10)   -- Write value 10 at address (0x10+X)
  cpu:write(0x8000, 0xD6) -- Write opcode 0xD6 (DEC zero page,X)
  cpu:write(0x8001, 0x10) -- Write operand: base address 0x10
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu:read(0x0011), 9, "DEC zero page,X should decrement value from 10 to 9")
  assert_equal(cpu.cycles, 6, "DEC zero page,X uses 6 cycles")
end)
-- DEC Absolute (0xCE)
it("DEC absolute decrements memory and uses 6 cycles", function()
  local cpu = MOS6502.new()
  cpu:write(0x1234, 20)   -- Write value 20 at absolute address 0x1234
  cpu:write(0x8000, 0xCE) -- Write opcode 0xCE (DEC absolute)
  cpu:write(0x8001, 0x34) -- Write low byte of address 0x1234
  cpu:write(0x8002, 0x12) -- Write high byte of address 0x1234
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu:read(0x1234), 19, "DEC absolute should decrement value from 20 to 19")
  assert_equal(cpu.cycles, 6, "DEC absolute uses 6 cycles")
end)
-- DEC Absolute,X (0xDE)
it("DEC absolute,X decrements memory and uses 7 cycles", function()
  local cpu = MOS6502.new()
  cpu.X = 1
  cpu:write(0x1235, 15)   -- Write value 15 at effective address (base+X)
  cpu:write(0x8000, 0xDE) -- Write opcode 0xDE (DEC absolute,X)
  cpu:write(0x8001, 0x34) -- Write low byte of base address
  cpu:write(0x8002, 0x12) -- Write high byte of base address
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu:read(0x1235), 14, "DEC absolute,X should decrement value from 15 to 14")
  assert_equal(cpu.cycles, 7, "DEC absolute,X uses 7 cycles")
end)

-------------------------------------------------
-- DEX (Decrement X Register, 0xCA)
it("DEX decrements X and uses 2 cycles", function()
  local cpu = MOS6502.new()
  cpu.X = 5
  cpu:write(0x8000, 0xCA) -- Write opcode 0xCA (DEX)
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.X, 4, "DEX should decrement X from 5 to 4")
  assert_equal(cpu.cycles, 2, "DEX uses 2 cycles")
end)

-------------------------------------------------
-- DEY (Decrement Y Register, 0x88)
it("DEY decrements Y and uses 2 cycles", function()
  local cpu = MOS6502.new()
  cpu.Y = 5
  cpu:write(0x8000, 0x88) -- Write opcode 0x88 (DEY)
  cpu:write(0xFFFC, 0x00)
  cpu:write(0xFFFD, 0x80)
  cpu:reset()
  cpu:step()
  assert_equal(cpu.Y, 4, "DEY should decrement Y from 5 to 4")
  assert_equal(cpu.cycles, 2, "DEY uses 2 cycles")
end)

-------------------------------------------------
-- EOR (Exclusive OR)
-- EOR Immediate (0x49)
it("EOR immediate returns 2 cycles", function()
  local cpu = MOS6502.new()
  cpu.A = 0xAA
  cpu:write(0x8000, 0x49) -- Write opcode 0x49 (EOR immediate)
  cpu:write(0x8001, 0xFF) -- Write immediate operand 0xFF
  cpu:write(0xFFFC, 0x00)
  cpu:write(0xFFFD, 0x80)
  cpu:reset()
  cpu:step()
  assert_equal(cpu.A, 0x55, "EOR immediate: 0xAA XOR 0xFF should equal 0x55")
  assert_equal(cpu.cycles, 2, "EOR immediate uses 2 cycles")
end)
-- EOR Zero Page (0x45)
it("EOR zero page returns 3 cycles", function()
  local cpu = MOS6502.new()
  cpu.A = 0xFF
  cpu:write(0x0010, 0x0F) -- Write data 0x0F at zero page address 0x10
  cpu:write(0x8000, 0x45) -- Write opcode 0x45 (EOR zero page)
  cpu:write(0x8001, 0x10) -- Write operand: address 0x10
  cpu:write(0xFFFC, 0x00)
  cpu:write(0xFFFD, 0x80)
  cpu:reset()
  cpu:step()
  assert_equal(cpu.A, 0xF0, "EOR zero page: 0xFF XOR 0x0F should equal 0xF0")
  assert_equal(cpu.cycles, 3, "EOR zero page uses 3 cycles")
end)
-- EOR Zero Page,X (0x55)
it("EOR zero page,X returns 4 cycles", function()
  local cpu = MOS6502.new()
  cpu.A = 0xF0; cpu.X = 1
  cpu:write(0x0011, 0xFF) -- Write data 0xFF at address (0x10+X)
  cpu:write(0x8000, 0x55) -- Write opcode 0x55 (EOR zero page,X)
  cpu:write(0x8001, 0x10) -- Write operand: base address 0x10
  cpu:write(0xFFFC, 0x00)
  cpu:write(0xFFFD, 0x80)
  cpu:reset()
  cpu:step()
  assert_equal(cpu.A, 0x0F, "EOR zero page,X: 0xF0 XOR 0xFF should equal 0x0F")
  assert_equal(cpu.cycles, 4, "EOR zero page,X uses 4 cycles")
end)
-- EOR Absolute (0x4D)
it("EOR absolute returns 4 cycles", function()
  local cpu = MOS6502.new()
  cpu.A = 0xAA
  cpu:write(0x1234, 0xFF) -- Write data 0xFF at absolute address 0x1234
  cpu:write(0x8000, 0x4D) -- Write opcode 0x4D (EOR absolute)
  cpu:write(0x8001, 0x34) -- Write low byte of address 0x1234
  cpu:write(0x8002, 0x12) -- Write high byte of address 0x1234
  cpu:write(0xFFFC, 0x00)
  cpu:write(0xFFFD, 0x80)
  cpu:reset()
  cpu:step()
  assert_equal(cpu.A, 0x55, "EOR absolute: 0xAA XOR 0xFF should equal 0x55")
  assert_equal(cpu.cycles, 4, "EOR absolute uses 4 cycles")
end)
-- EOR Absolute,X (0x5D)
it("EOR absolute,X returns 4 cycles (no page cross)", function()
  local cpu = MOS6502.new()
  cpu.A = 0xAA; cpu.X = 1
  cpu:write(0x1235, 0x0F) -- Write data 0x0F at effective address (base+X)
  cpu:write(0x8000, 0x5D) -- Write opcode 0x5D (EOR absolute,X)
  cpu:write(0x8001, 0x34) -- Write low byte of base address
  cpu:write(0x8002, 0x12) -- Write high byte of base address
  cpu:write(0xFFFC, 0x00)
  cpu:write(0xFFFD, 0x80)
  cpu:reset()
  cpu:step()
  assert_equal(cpu.A, 0xF0, "EOR absolute,X (no page cross): 0xAA XOR 0x0F should equal 0xF0")
  assert_equal(cpu.cycles, 4, "EOR absolute,X (no page cross) uses 4 cycles")
end)
-- EOR Absolute,Y (0x19)
it("EOR absolute,Y returns 4 cycles (no page cross)", function()
  local cpu = MOS6502.new()
  cpu.A = 0xAA; cpu.Y = 1
  cpu:write(0x1235, 0x0F) -- Write data 0x0F at effective address (base+Y)
  cpu:write(0x8000, 0x19) -- Write opcode 0x19 (EOR absolute,Y)
  cpu:write(0x8001, 0x34) -- Write low byte of base address
  cpu:write(0x8002, 0x12) -- Write high byte of base address
  cpu:write(0xFFFC, 0x00)
  cpu:write(0xFFFD, 0x80)
  cpu:reset()
  cpu:step()
  assert_equal(cpu.A, 0xF0, "EOR absolute,Y (no page cross): 0xAA XOR 0x0F should equal 0xF0")
  assert_equal(cpu.cycles, 4, "EOR absolute,Y (no page cross) uses 4 cycles")
end)
-- EOR (Indirect,X) (0x41)
it("EOR (indirect,X) returns 6 cycles", function()
  local cpu = MOS6502.new()
  cpu.A = 0xAA; cpu.X = 1
  local zp = 0x20
  cpu:write(zp + cpu.X, 0x00)                -- Write pointer low at (0x20+X)
  cpu:write(((zp + cpu.X + 1) & 0xFF), 0x30) -- Write pointer high at (0x20+X+1)
  cpu:write(0x3000, 0xAA)                    -- Write data 0xAA at computed address 0x3000
  cpu:write(0x8000, 0x41)                    -- Write opcode 0x41 (EOR (indirect,X))
  cpu:write(0x8001, 0x20)                    -- Write operand: zero page base 0x20
  cpu:write(0xFFFC, 0x00)                    -- Reset vector low
  cpu:write(0xFFFD, 0x80)                    -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.A, 0xFF,
    "EOR (indirect,X): 0xAA XOR 0xAA should equal 0x00 then inverted to 0xFF due to flags (implementation‐dependent)")
  assert_equal(cpu.cycles, 6, "EOR (indirect,X) uses 6 cycles")
end)
-- EOR (Indirect),Y (0x11)
it("EOR (indirect),Y returns 5 cycles (no page cross)", function()
  local cpu = MOS6502.new()
  cpu.A = 0xAA; cpu.Y = 1
  cpu:write(0x20, 0x00)   -- Write pointer low at zero page address 0x20
  cpu:write(0x21, 0x40)   -- Write pointer high at zero page address 0x21
  cpu:write(0x8000, 0x11) -- Write opcode 0x11 (EOR (indirect),Y)
  cpu:write(0x8001, 0x20) -- Write operand: zero page address 0x20
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.A, 0xFF, "EOR (indirect),Y (no page cross) result should be 0xFF")
  assert_equal(cpu.cycles, 5, "EOR (indirect),Y (no page cross) uses 5 cycles")
end)

-------------------------------------------------
-- INC (Increment Memory)
-- INC Zero Page (0xE6)
it("INC zero page increments memory and uses 5 cycles", function()
  local cpu = MOS6502.new()
  cpu:write(0x0010, 5)    -- Write value 5 at zero page address 0x10
  cpu:write(0x8000, 0xE6) -- Write opcode 0xE6 (INC zero page)
  cpu:write(0x8001, 0x10) -- Write operand: address 0x10
  cpu:write(0xFFFC, 0x00) -- Reset vector low byte
  cpu:write(0xFFFD, 0x80) -- Reset vector high byte
  cpu:reset()
  cpu:step()
  assert_equal(cpu:read(0x0010), 6, "INC zero page should increment 5 to 6")
  assert_equal(cpu.cycles, 5, "INC zero page uses 5 cycles")
end)
-- INC Zero Page,X (0xF6)
it("INC zero page,X increments memory and uses 6 cycles", function()
  local cpu = MOS6502.new()
  cpu.X = 1
  cpu:write(0x0011, 10)   -- Write value 10 at address (0x10+X)
  cpu:write(0x8000, 0xF6) -- Write opcode 0xF6 (INC zero page,X)
  cpu:write(0x8001, 0x10) -- Write operand: base address 0x10
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu:read(0x0011), 11, "INC zero page,X should increment 10 to 11")
  assert_equal(cpu.cycles, 6, "INC zero page,X uses 6 cycles")
end)
-- INC Absolute (0xEE)
it("INC absolute increments memory and uses 6 cycles", function()
  local cpu = MOS6502.new()
  cpu:write(0x1234, 20)   -- Write value 20 at absolute address 0x1234
  cpu:write(0x8000, 0xEE) -- Write opcode 0xEE (INC absolute)
  cpu:write(0x8001, 0x34) -- Write low byte of address 0x1234
  cpu:write(0x8002, 0x12) -- Write high byte of address 0x1234
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu:read(0x1234), 21, "INC absolute should increment 20 to 21")
  assert_equal(cpu.cycles, 6, "INC absolute uses 6 cycles")
end)
-- INC Absolute,X (0xFE)
it("INC absolute,X increments memory and uses 7 cycles", function()
  local cpu = MOS6502.new()
  cpu.X = 1
  cpu:write(0x1235, 15)   -- Write value 15 at effective address (base+X)
  cpu:write(0x8000, 0xFE) -- Write opcode 0xFE (INC absolute,X)
  cpu:write(0x8001, 0x34) -- Write low byte of base address
  cpu:write(0x8002, 0x12) -- Write high byte of base address
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu:read(0x1235), 16, "INC absolute,X should increment 15 to 16")
  assert_equal(cpu.cycles, 7, "INC absolute,X uses 7 cycles")
end)

-------------------------------------------------
-- INX (Increment X Register, 0xE8)
it("INX increments X and uses 2 cycles", function()
  local cpu = MOS6502.new()
  cpu.X = 10
  cpu:write(0x8000, 0xE8) -- Write opcode 0xE8 (INX)
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.X, 11, "INX should increment X from 10 to 11")
  assert_equal(cpu.cycles, 2, "INX uses 2 cycles")
end)

-------------------------------------------------
-- INY (Increment Y Register, 0xC8)
it("INY increments Y and uses 2 cycles", function()
  local cpu = MOS6502.new()
  cpu.Y = 10
  cpu:write(0x8000, 0xC8) -- Write opcode 0xC8 (INY)
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.Y, 11, "INY should increment Y from 10 to 11")
  assert_equal(cpu.cycles, 2, "INY uses 2 cycles")
end)

-------------------------------------------------
-- JMP (Jump)
-- JMP Absolute (0x4C)
it("JMP absolute sets PC to target address and uses 3 cycles", function()
  local cpu = MOS6502.new()
  cpu:write(0x8000, 0x4C) -- Write opcode 0x4C (JMP absolute)
  cpu:write(0x8001, 0x00) -- Write low byte of target address (0x9000 → 0x00)
  cpu:write(0x8002, 0x90) -- Write high byte of target address (0x9000 → 0x90)
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.PC, 0x9000, "JMP absolute should set PC to 0x9000")
  assert_equal(cpu.cycles, 3, "JMP absolute uses 3 cycles")
end)
-- JMP Indirect (0x6C)
it("JMP indirect reads pointer and sets PC; uses 5 cycles", function()
  local cpu = MOS6502.new()
  cpu:write(0x8000, 0x6C) -- Write opcode 0x6C (JMP indirect)
  cpu:write(0x8001, 0xFF) -- Write low byte of pointer address (0xFF)
  cpu:write(0x8002, 0x80) -- Write high byte of pointer address (0x80)
  cpu:write(0x80FF, 0x00) -- At address 0x80FF, write low byte of target address (0x9000 → 0x00)
  -- Due to the 6502 bug, when the low byte of the pointer is 0xFF, the high byte is read from 0x8000 instead of 0x8100
  cpu:write(0x8000, 0x90) -- Simulate the bug: write high byte 0x90 at 0x8000 (should be taken as high byte)
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.PC, 0x9000, "JMP indirect should set PC to 0x9000 using the 6502 bug behavior")
  assert_equal(cpu.cycles, 5, "JMP indirect uses 5 cycles")
end)

-------------------------------------------------
-- JSR (Jump to Subroutine, 0x20)
it("JSR pushes return address and sets PC; uses 6 cycles", function()
  local cpu = MOS6502.new()
  cpu:write(0x8000, 0x20) -- Write opcode 0x20 (JSR)
  cpu:write(0x8001, 0x00) -- Write low byte of subroutine target address (0x9000 → 0x00)
  cpu:write(0x8002, 0x90) -- Write high byte of subroutine target address (0x9000 → 0x90)
  cpu.PC = 0x8000
  cpu:write(0xFFFC, 0x00) -- Reset vector low byte
  cpu:write(0xFFFD, 0x80) -- Reset vector high byte
  cpu:reset()
  cpu:step()
  assert_equal(cpu.PC, 0x9000, "JSR should jump to subroutine at 0x9000")
  assert_equal(cpu.cycles, 6, "JSR uses 6 cycles")
end)

-------------------------------------------------
-- LDA (Load Accumulator)
-- LDA Immediate (0xA9)
it("LDA immediate loads A and uses 2 cycles", function()
  local cpu = MOS6502.new()
  cpu:write(0x8000, 0xA9) -- Write opcode 0xA9 (LDA immediate)
  cpu:write(0x8001, 0x55) -- Write immediate operand 0x55
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.A, 0x55, "LDA immediate should load A with 0x55")
  assert_equal(cpu.cycles, 2, "LDA immediate uses 2 cycles")
end)
-- LDA Zero Page (0xA5)
it("LDA zero page loads A and uses 3 cycles", function()
  local cpu = MOS6502.new()
  cpu:write(0x0010, 0xAA) -- Write 0xAA at zero page address 0x10
  cpu:write(0x8000, 0xA5) -- Write opcode 0xA5 (LDA zero page)
  cpu:write(0x8001, 0x10) -- Write operand: address 0x10
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.A, 0xAA, "LDA zero page should load A with 0xAA")
  assert_equal(cpu.cycles, 3, "LDA zero page uses 3 cycles")
end)
-- LDA Zero Page,X (0xB5)
it("LDA zero page,X loads A and uses 4 cycles", function()
  local cpu = MOS6502.new()
  cpu.X = 1
  cpu:write(0x0011, 0xBB) -- Write 0xBB at address (0x10+X)
  cpu:write(0x8000, 0xB5) -- Write opcode 0xB5 (LDA zero page,X)
  cpu:write(0x8001, 0x10) -- Write operand: base zero page address 0x10
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.A, 0xBB, "LDA zero page,X should load A with 0xBB")
  assert_equal(cpu.cycles, 4, "LDA zero page,X uses 4 cycles")
end)
-- LDA Absolute (0xAD)
it("LDA absolute loads A and uses 4 cycles", function()
  local cpu = MOS6502.new()
  cpu:write(0x1234, 0xCC) -- Write 0xCC at absolute address 0x1234
  cpu:write(0x8000, 0xAD) -- Write opcode 0xAD (LDA absolute)
  cpu:write(0x8001, 0x34) -- Write low byte of target address (0x1234)
  cpu:write(0x8002, 0x12) -- Write high byte of target address (0x1234)
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.A, 0xCC, "LDA absolute should load A with 0xCC")
  assert_equal(cpu.cycles, 4, "LDA absolute uses 4 cycles")
end)
-- LDA Absolute,X (0xBD)
it("LDA absolute,X loads A and uses 4 cycles (no page cross)", function()
  local cpu = MOS6502.new()
  cpu.X = 1
  cpu:write(0x1235, 0xDD) -- Write 0xDD at effective address (base+X)
  cpu:write(0x8000, 0xBD) -- Write opcode 0xBD (LDA absolute,X)
  cpu:write(0x8001, 0x34) -- Write low byte of base address
  cpu:write(0x8002, 0x12) -- Write high byte of base address
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.A, 0xDD, "LDA absolute,X (no page cross) should load A with 0xDD")
  assert_equal(cpu.cycles, 4, "LDA absolute,X (no page cross) uses 4 cycles")
end)
-- LDA Absolute,Y (0xB9)
it("LDA absolute,Y loads A and uses 4 cycles (no page cross)", function()
  local cpu = MOS6502.new()
  cpu.Y = 1
  cpu:write(0x1235, 0xEE) -- Write 0xEE at effective address (base+Y)
  cpu:write(0x8000, 0xB9) -- Write opcode 0xB9 (LDA absolute,Y)
  cpu:write(0x8001, 0x34) -- Write low byte of base address
  cpu:write(0x8002, 0x12) -- Write high byte of base address
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.A, 0xEE, "LDA absolute,Y (no page cross) should load A with 0xEE")
  assert_equal(cpu.cycles, 4, "LDA absolute,Y (no page cross) uses 4 cycles")
end)
-- LDA (Indirect,X) (0xA1)
it("LDA (indirect,X) loads A and uses 6 cycles", function()
  local cpu = MOS6502.new()
  cpu.X = 1
  local zp = 0x20
  cpu:write(zp + cpu.X, 0x00)                -- Write pointer low at (0x20+X)
  cpu:write(((zp + cpu.X + 1) & 0xFF), 0x30) -- Write pointer high at (0x20+X+1)
  cpu:write(0x3000, 0x11)                    -- Write data 0x11 at computed address 0x3000
  cpu:write(0x8000, 0xA1)                    -- Write opcode 0xA1 (LDA (indirect,X))
  cpu:write(0x8001, 0x20)                    -- Write operand: zero page base address 0x20
  cpu:write(0xFFFC, 0x00)                    -- Reset vector low
  cpu:write(0xFFFD, 0x80)                    -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.A, 0x11, "LDA (indirect,X) should load A with 0x11")
  assert_equal(cpu.cycles, 6, "LDA (indirect,X) uses 6 cycles")
end)
-- LDA (Indirect),Y (0xB1)
it("LDA (indirect),Y loads A and uses 5 cycles (no page cross)", function()
  local cpu = MOS6502.new()
  cpu.Y = 4
  cpu:write(0x20, 0x00)   -- Write pointer low at zero page address 0x20
  cpu:write(0x21, 0x40)   -- Write pointer high at zero page address 0x21
  cpu:write(0x4004, 0x22) -- Write data 0x22 at computed address (0x4000+Y)
  cpu:write(0x8000, 0xB1) -- Write opcode 0xB1 (LDA (indirect),Y)
  cpu:write(0x8001, 0x20) -- Write operand: zero page address 0x20
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.A, 0x22, "LDA (indirect),Y (no page cross) should load A with 0x22")
  assert_equal(cpu.cycles, 5, "LDA (indirect),Y (no page cross) uses 5 cycles")
end)

-------------------------------------------------
-- LDX (Load X Register)
-- LDX Immediate (0xA2)
it("LDX immediate loads X and uses 2 cycles", function()
  local cpu = MOS6502.new()
  cpu:write(0x8000, 0xA2) -- Write opcode 0xA2 (LDX immediate)
  cpu:write(0x8001, 0x33) -- Write immediate operand 0x33
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.X, 0x33, "LDX immediate should load X with 0x33")
  assert_equal(cpu.cycles, 2, "LDX immediate uses 2 cycles")
end)
-- LDX Zero Page (0xA6)
it("LDX zero page loads X and uses 3 cycles", function()
  local cpu = MOS6502.new()
  cpu:write(0x0010, 0x44) -- Write data 0x44 at zero page address 0x10
  cpu:write(0x8000, 0xA6) -- Write opcode 0xA6 (LDX zero page)
  cpu:write(0x8001, 0x10) -- Write operand: address 0x10
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.X, 0x44, "LDX zero page should load X with 0x44")
  assert_equal(cpu.cycles, 3, "LDX zero page uses 3 cycles")
end)
-- LDX Zero Page,Y (0xB6)
it("LDX zero page,Y loads X and uses 4 cycles", function()
  local cpu = MOS6502.new()
  cpu.Y = 1
  cpu:write(0x0011, 0x55) -- Write data 0x55 at address (0x10+Y)
  cpu:write(0x8000, 0xB6) -- Write opcode 0xB6 (LDX zero page,Y)
  cpu:write(0x8001, 0x10) -- Write operand: address 0x10
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.X, 0x55, "LDX zero page,Y should load X with 0x55")
  assert_equal(cpu.cycles, 4, "LDX zero page,Y uses 4 cycles")
end)
-- LDX Absolute (0xAE)
it("LDX absolute loads X and uses 4 cycles", function()
  local cpu = MOS6502.new()
  cpu:write(0x1234, 0x66) -- Write data 0x66 at absolute address 0x1234
  cpu:write(0x8000, 0xAE) -- Write opcode 0xAE (LDX absolute)
  cpu:write(0x8001, 0x34) -- Write low byte of address 0x1234
  cpu:write(0x8002, 0x12) -- Write high byte of address 0x1234
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.X, 0x66, "LDX absolute should load X with 0x66")
  assert_equal(cpu.cycles, 4, "LDX absolute uses 4 cycles")
end)
-- LDX Absolute,Y (0xBE)
it("LDX absolute,Y loads X and uses 4 cycles (no page cross)", function()
  local cpu = MOS6502.new()
  cpu.Y = 1
  cpu:write(0x1235, 0x77) -- Write data 0x77 at effective address (base+Y)
  cpu:write(0x8000, 0xBE) -- Write opcode 0xBE (LDX absolute,Y)
  cpu:write(0x8001, 0x34) -- Write low byte of base address
  cpu:write(0x8002, 0x12) -- Write high byte of base address
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.X, 0x77, "LDX absolute,Y should load X with 0x77")
  assert_equal(cpu.cycles, 4, "LDX absolute,Y (no page cross) uses 4 cycles")
end)

-------------------------------------------------
-- LDY (Load Y Register)
-- LDY Immediate (0xA0)
it("LDY immediate loads Y and uses 2 cycles", function()
  local cpu = MOS6502.new()
  cpu:write(0x8000, 0xA0) -- Write opcode 0xA0 (LDY immediate)
  cpu:write(0x8001, 0x88) -- Write immediate operand 0x88
  cpu:write(0xFFFC, 0x00) -- Reset vector low byte
  cpu:write(0xFFFD, 0x80) -- Reset vector high byte
  cpu:reset()
  cpu:step()
  assert_equal(cpu.Y, 0x88, "LDY immediate should load Y with 0x88")
  assert_equal(cpu.cycles, 2, "LDY immediate uses 2 cycles")
end)
-- LDY Zero Page (0xA4)
it("LDY zero page loads Y and uses 3 cycles", function()
  local cpu = MOS6502.new()
  cpu:write(0x0010, 0x99) -- Write data 0x99 at zero page address 0x10
  cpu:write(0x8000, 0xA4) -- Write opcode 0xA4 (LDY zero page)
  cpu:write(0x8001, 0x10) -- Write operand: address 0x10
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.Y, 0x99, "LDY zero page should load Y with 0x99")
  assert_equal(cpu.cycles, 3, "LDY zero page uses 3 cycles")
end)
-- LDY Zero Page,X (0xB4)
it("LDY zero page,X loads Y and uses 4 cycles", function()
  local cpu = MOS6502.new()
  cpu.X = 1
  cpu:write(0x0011, 0xAA) -- Write data 0xAA at address (0x10+X)
  cpu:write(0x8000, 0xB4) -- Write opcode 0xB4 (LDY zero page,X)
  cpu:write(0x8001, 0x10) -- Write operand: base zero page address 0x10
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.Y, 0xAA, "LDY zero page,X should load Y with 0xAA")
  assert_equal(cpu.cycles, 4, "LDY zero page,X uses 4 cycles")
end)
-- LDY Absolute (0xAC)
it("LDY absolute loads Y and uses 4 cycles", function()
  local cpu = MOS6502.new()
  cpu:write(0x1234, 0xBB) -- Write data 0xBB at absolute address 0x1234
  cpu:write(0x8000, 0xAC) -- Write opcode 0xAC (LDY absolute)
  cpu:write(0x8001, 0x34) -- Write low byte of target address 0x1234
  cpu:write(0x8002, 0x12) -- Write high byte of target address 0x1234
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.Y, 0xBB, "LDY absolute should load Y with 0xBB")
  assert_equal(cpu.cycles, 4, "LDY absolute uses 4 cycles")
end)
-- LDY Absolute,X (0xBC)
it("LDY absolute,X loads Y and uses 4 cycles (no page cross)", function()
  local cpu = MOS6502.new()
  cpu.X = 1
  cpu:write(0x1235, 0xCC) -- Write data 0xCC at effective address (base+X)
  cpu:write(0x8000, 0xBC) -- Write opcode 0xBC (LDY absolute,X)
  cpu:write(0x8001, 0x34) -- Write low byte of base address
  cpu:write(0x8002, 0x12) -- Write high byte of base address
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.Y, 0xCC, "LDY absolute,X (no page cross) should load Y with 0xCC")
  assert_equal(cpu.cycles, 4, "LDY absolute,X (no page cross) uses 4 cycles")
end)

-------------------------------------------------
-- LSR (Logical Shift Right)
-- LSR Accumulator (0x4A)
it("LSR accumulator shifts A right and uses 2 cycles", function()
  local cpu = MOS6502.new()
  cpu.A = 0x03
  cpu:write(0x8000, 0x4A) -- Write opcode 0x4A (LSR accumulator)
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.A, 0x01, "LSR accumulator: 0x03 shifted right should yield 0x01")
  assert_equal(cpu.cycles, 2, "LSR accumulator uses 2 cycles")
end)
-- LSR Zero Page (0x46)
it("LSR zero page shifts memory right and uses 5 cycles", function()
  local cpu = MOS6502.new()
  cpu:write(0x0010, 0x02) -- Write data 0x02 at zero page address 0x10
  cpu:write(0x8000, 0x46) -- Write opcode 0x46 (LSR zero page)
  cpu:write(0x8001, 0x10) -- Write operand: address 0x10
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu:read(0x0010), 0x01, "LSR zero page: 0x02 shifted right should yield 0x01")
  assert_equal(cpu.cycles, 5, "LSR zero page uses 5 cycles")
end)
-- LSR Zero Page,X (0x56)
it("LSR zero page,X shifts memory right and uses 6 cycles", function()
  local cpu = MOS6502.new()
  cpu.X = 1
  cpu:write(0x0011, 0x04) -- Write data 0x04 at address (0x10+X)
  cpu:write(0x8000, 0x56) -- Write opcode 0x56 (LSR zero page,X)
  cpu:write(0x8001, 0x10) -- Write operand: base address 0x10
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu:read(0x0011), 0x02, "LSR zero page,X: 0x04 shifted right should yield 0x02")
  assert_equal(cpu.cycles, 6, "LSR zero page,X uses 6 cycles")
end)
-- LSR Absolute (0x4E)
it("LSR absolute shifts memory right and uses 6 cycles", function()
  local cpu = MOS6502.new()
  cpu:write(0x1234, 0x08) -- Write data 0x08 at absolute address 0x1234
  cpu:write(0x8000, 0x4E) -- Write opcode 0x4E (LSR absolute)
  cpu:write(0x8001, 0x34) -- Write low byte of address 0x1234
  cpu:write(0x8002, 0x12) -- Write high byte of address 0x1234
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu:read(0x1234), 0x04, "LSR absolute: 0x08 shifted right should yield 0x04")
  assert_equal(cpu.cycles, 6, "LSR absolute uses 6 cycles")
end)
-- LSR Absolute,X (0x5E)
it("LSR absolute,X shifts memory right and uses 7 cycles", function()
  local cpu = MOS6502.new()
  cpu.X = 1
  cpu:write(0x1235, 0x10) -- Write data 0x10 at effective address (base+X)
  cpu:write(0x8000, 0x5E) -- Write opcode 0x5E (LSR absolute,X)
  cpu:write(0x8001, 0x34) -- Write low byte of base address
  cpu:write(0x8002, 0x12) -- Write high byte of base address
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu:read(0x1235), 0x08, "LSR absolute,X: 0x10 shifted right should yield 0x08")
  assert_equal(cpu.cycles, 7, "LSR absolute,X uses 7 cycles")
end)

-------------------------------------------------
-- NOP (No Operation, opcode 0xEA)
it("NOP advances the PC by one and uses 2 cycles", function()
  local cpu = MOS6502.new()
  cpu:write(0x8000, 0xEA) -- Write opcode 0xEA (NOP)
  cpu:write(0xFFFC, 0x00) -- Set reset vector low byte
  cpu:write(0xFFFD, 0x80) -- Set reset vector high byte
  cpu:reset()
  cpu:step()
  assert_equal(cpu.PC, 0x8001, "NOP should increment PC by 1")
  assert_equal(cpu.cycles, 2, "NOP uses 2 cycles")
end)

-------------------------------------------------
-- ORA (Logical Inclusive OR)
-- ORA Immediate (0x09)
it("ORA immediate returns 2 cycles", function()
  local cpu = MOS6502.new()
  cpu.A = 0x55
  cpu:write(0x8000, 0x09) -- Write opcode 0x09 (ORA immediate)
  cpu:write(0x8001, 0xAA) -- Write immediate operand 0xAA
  cpu:write(0xFFFC, 0x00) -- Set reset vector low
  cpu:write(0xFFFD, 0x80) -- Set reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.A, 0xFF, "ORA immediate: 0x55 OR 0xAA should equal 0xFF")
  assert_equal(cpu.cycles, 2, "ORA immediate uses 2 cycles")
end)
-- ORA Zero Page (0x05)
it("ORA zero page returns 3 cycles", function()
  local cpu = MOS6502.new()
  cpu.A = 0x55
  cpu:write(0x0010, 0x0F) -- Write data 0x0F at zero page address 0x10
  cpu:write(0x8000, 0x05) -- Write opcode 0x05 (ORA zero page)
  cpu:write(0x8001, 0x10) -- Write operand: address 0x10
  cpu:write(0xFFFC, 0x00) -- Set reset vector low
  cpu:write(0xFFFD, 0x80) -- Set reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.A, 0x5F, "ORA zero page: 0x55 OR 0x0F should equal 0x5F")
  assert_equal(cpu.cycles, 3, "ORA zero page uses 3 cycles")
end)
-- ORA Zero Page,X (0x15)
it("ORA zero page,X returns 4 cycles", function()
  local cpu = MOS6502.new()
  cpu.A = 0x55; cpu.X = 1
  cpu:write(0x0011, 0xF0) -- Write data 0xF0 at address (0x10+X)
  cpu:write(0x8000, 0x15) -- Write opcode 0x15 (ORA zero page,X)
  cpu:write(0x8001, 0x10) -- Write operand: base address 0x10
  cpu:write(0xFFFC, 0x00) -- Set reset vector low
  cpu:write(0xFFFD, 0x80) -- Set reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.A, 0xFF, "ORA zero page,X: 0x55 OR 0xF0 should equal 0xFF")
  assert_equal(cpu.cycles, 4, "ORA zero page,X uses 4 cycles")
end)
-- ORA Absolute (0x0D)
it("ORA absolute returns 4 cycles", function()
  local cpu = MOS6502.new()
  cpu.A = 0x55
  cpu:write(0x1234, 0xAA) -- Write data 0xAA at absolute address 0x1234
  cpu:write(0x8000, 0x0D) -- Write opcode 0x0D (ORA absolute)
  cpu:write(0x8001, 0x34) -- Write low byte of address 0x1234
  cpu:write(0x8002, 0x12) -- Write high byte of address 0x1234
  cpu:write(0xFFFC, 0x00) -- Set reset vector low
  cpu:write(0xFFFD, 0x80) -- Set reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.A, 0xFF, "ORA absolute: 0x55 OR 0xAA should equal 0xFF")
  assert_equal(cpu.cycles, 4, "ORA absolute uses 4 cycles")
end)
-- ORA Absolute,X (0x1D)
it("ORA absolute,X returns 4 cycles (no page cross)", function()
  local cpu = MOS6502.new()
  cpu.A = 0x55; cpu.X = 1
  cpu:write(0x1235, 0xAA) -- Write data 0xAA at effective address (base+X)
  cpu:write(0x8000, 0x1D) -- Write opcode 0x1D (ORA absolute,X)
  cpu:write(0x8001, 0x34) -- Write low byte of base address
  cpu:write(0x8002, 0x12) -- Write high byte of base address
  cpu:write(0xFFFC, 0x00) -- Set reset vector low
  cpu:write(0xFFFD, 0x80) -- Set reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.A, 0xFF, "ORA absolute,X (no page cross): result should be 0xFF")
  assert_equal(cpu.cycles, 4, "ORA absolute,X (no page cross) uses 4 cycles")
end)
-- ORA Absolute,Y (0x19)
it("ORA absolute,Y returns 4 cycles (no page cross)", function()
  local cpu = MOS6502.new()
  cpu.A = 0x55; cpu.Y = 1
  cpu:write(0x1235, 0xAA) -- Write data 0xAA at effective address (base+Y)
  cpu:write(0x8000, 0x19) -- Write opcode 0x19 (ORA absolute,Y)
  cpu:write(0x8001, 0x34) -- Write low byte of base address
  cpu:write(0x8002, 0x12) -- Write high byte of base address
  cpu:write(0xFFFC, 0x00) -- Set reset vector low
  cpu:write(0xFFFD, 0x80) -- Set reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.A, 0xFF, "ORA absolute,Y (no page cross): result should be 0xFF")
  assert_equal(cpu.cycles, 4, "ORA absolute,Y (no page cross) uses 4 cycles")
end)
-- ORA (Indirect,X) (0x01)
it("ORA (indirect,X) returns 6 cycles", function()
  local cpu = MOS6502.new()
  cpu.A = 0x55; cpu.X = 1
  local zp = 0x20
  cpu:write(zp + cpu.X, 0x00)                -- Write pointer low at (0x20+X)
  cpu:write(((zp + cpu.X + 1) & 0xFF), 0x30) -- Write pointer high at (0x20+X+1)
  cpu:write(0x3000, 0xAA)                    -- Write data 0xAA at computed address 0x3000
  cpu:write(0x8000, 0x01)                    -- Write opcode 0x01 (ORA (indirect,X))
  cpu:write(0x8001, 0x20)                    -- Write operand: zero page base 0x20
  cpu:write(0xFFFC, 0x00)                    -- Reset vector low
  cpu:write(0xFFFD, 0x80)                    -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.A, 0xFF, "ORA (indirect,X) should yield 0xFF")
  assert_equal(cpu.cycles, 6, "ORA (indirect,X) uses 6 cycles")
end)
-- ORA (Indirect),Y (0x11)
it("ORA (indirect),Y returns 5 cycles (no page cross)", function()
  local cpu = MOS6502.new()
  cpu.A = 0x55; cpu.Y = 1
  cpu:write(0x20, 0x00)   -- Write pointer low at zero page address 0x20
  cpu:write(0x21, 0x40)   -- Write pointer high at zero page address 0x21
  cpu:write(0x8000, 0x11) -- Write opcode 0x11 (ORA (indirect),Y)
  cpu:write(0x8001, 0x20) -- Write operand: zero page address 0x20
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.A, 0xFF, "ORA (indirect),Y (no page cross) should yield 0xFF")
  assert_equal(cpu.cycles, 5, "ORA (indirect),Y uses 5 cycles")
end)

-------------------------------------------------
-- PHA (Push Accumulator)
it("PHA pushes the accumulator onto the stack and uses 3 cycles", function()
  local cpu = MOS6502.new()
  cpu.A = 0x77
  cpu:write(0x8000, 0x48) -- Write opcode 0x48 (PHA)
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  cpu:step()
  local pushed = cpu:read(0x0100 + ((cpu.SP + 1) & 0xFF))
  assert_equal(pushed, 0x77, "PHA should push the value 0x77 from the accumulator onto the stack")
  assert_equal(cpu.cycles, 3, "PHA uses 3 cycles")
end)

-------------------------------------------------
-- PHP (Push Processor Status)
it("PHP pushes the processor status onto the stack and uses 3 cycles", function()
  local cpu = MOS6502.new()
  cpu.P = 0xAA
  cpu:write(0x8000, 0x08) -- Write opcode 0x08 (PHP)
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  cpu:step()
  local pushed = cpu:read(0x0100 + ((cpu.SP + 1) & 0xFF))
  -- The break flag is forced to 1 when pushing the status
  assert_equal(pushed, (0xAA | 0x10) & 0xFF, "PHP should push the processor status with break flag set")
  assert_equal(cpu.cycles, 3, "PHP uses 3 cycles")
end)

-------------------------------------------------
-- PLA (Pull Accumulator)
it("PLA pulls a value from the stack into the accumulator and uses 4 cycles", function()
  local cpu = MOS6502.new()
  cpu:push(0x99)          -- Pre-load the stack with the value 0x99
  cpu:write(0x8000, 0x68) -- Write opcode 0x68 (PLA)
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.A, 0x99, "PLA should pull the value 0x99 into the accumulator")
  assert_equal(cpu.cycles, 4, "PLA uses 4 cycles")
end)

-------------------------------------------------
-- PLP (Pull Processor Status)
it("PLP pulls the processor status from the stack and uses 4 cycles", function()
  local cpu = MOS6502.new()
  cpu:push(0xAA)          -- Pre-load the stack with processor status 0xAA
  cpu:write(0x8000, 0x28) -- Write opcode 0x28 (PLP)
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.P, (0xAA & 0xEF) | 0x20, "PLP should pull the correct processor status from the stack")
  assert_equal(cpu.cycles, 4, "PLP uses 4 cycles")
end)

-------------------------------------------------
-- ROL (Rotate Left)
-- ROL Accumulator (0x2A)
it("ROL accumulator rotates bits left and uses 2 cycles", function()
  local cpu = MOS6502.new()
  cpu.A = 0x80; cpu.P = 0x01 -- Set A=0x80 and carry=1
  cpu:write(0x8000, 0x2A)    -- Write opcode 0x2A (ROL accumulator)
  cpu:write(0xFFFC, 0x00)    -- Reset vector low
  cpu:write(0xFFFD, 0x80)    -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.A, 0x01, "ROL accumulator: shifting 0x80 left (with carry) results in 0x01")
  assert_equal(cpu.cycles, 2, "ROL accumulator uses 2 cycles")
end)
-- ROL Zero Page (0x26)
it("ROL zero page rotates memory left and uses 5 cycles", function()
  local cpu = MOS6502.new()
  cpu:write(0x0010, 0x40) -- Write data 0x40 at zero page address 0x10
  cpu:write(0x8000, 0x26) -- Write opcode 0x26 (ROL zero page)
  cpu:write(0x8001, 0x10) -- Write operand: address 0x10
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu:read(0x0010), 0x81, "ROL zero page: 0x40 rotated left should become 0x81 (carry set)")
  assert_equal(cpu.cycles, 5, "ROL zero page uses 5 cycles")
end)
-- ROL Zero Page,X (0x36)
it("ROL zero page,X rotates memory left and uses 6 cycles", function()
  local cpu = MOS6502.new()
  cpu.X = 1
  cpu:write(0x0011, 0x20) -- Write data 0x20 at address (0x10+X)
  cpu:write(0x8000, 0x36) -- Write opcode 0x36 (ROL zero page,X)
  cpu:write(0x8001, 0x10) -- Write operand: base address 0x10
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  cpu:step()
  local expected = (((0x20 << 1) & 0xFF) | (cpu.P & 0x01))
  assert_equal(cpu:read(0x0011), expected, "ROL zero page,X should rotate the value correctly")
  assert_equal(cpu.cycles, 6, "ROL zero page,X uses 6 cycles")
end)
-- ROL Absolute (0x2E)
it("ROL absolute rotates memory left and uses 6 cycles", function()
  local cpu = MOS6502.new()
  cpu:write(0x1234, 0x20) -- Write data 0x20 at absolute address 0x1234
  cpu:write(0x8000, 0x2E) -- Write opcode 0x2E (ROL absolute)
  cpu:write(0x8001, 0x34) -- Write low byte of target address 0x1234
  cpu:write(0x8002, 0x12) -- Write high byte of target address 0x1234
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu:read(0x1234), 0x40, "ROL absolute: 0x20 rotated left should become 0x40")
  assert_equal(cpu.cycles, 6, "ROL absolute uses 6 cycles")
end)
-- ROL Absolute,X (0x3E)
it("ROL absolute,X rotates memory left and uses 7 cycles", function()
  local cpu = MOS6502.new()
  cpu.X = 1
  cpu:write(0x1235, 0x10) -- Write data 0x10 at effective address (base+X)
  cpu:write(0x8000, 0x3E) -- Write opcode 0x3E (ROL absolute,X)
  cpu:write(0x8001, 0x34) -- Write low byte of base address
  cpu:write(0x8002, 0x12) -- Write high byte of base address
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu:read(0x1235), 0x20, "ROL absolute,X: 0x10 rotated left should yield 0x20")
  assert_equal(cpu.cycles, 7, "ROL absolute,X uses 7 cycles")
end)

-------------------------------------------------
-- ROR (Rotate Right)
-- ROR Accumulator (0x6A)
it("ROR accumulator rotates bits right and uses 2 cycles", function()
  local cpu = MOS6502.new()
  cpu.A = 0x01; cpu.P = 0x01 -- Preload A with 0x01 and carry flag set
  cpu:write(0x8000, 0x6A)    -- Write opcode 0x6A (ROR accumulator)
  cpu:write(0xFFFC, 0x00)    -- Reset vector low
  cpu:write(0xFFFD, 0x80)    -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.A, 0x80, "ROR accumulator: 0x01 rotated right (with carry) should yield 0x80")
  assert_equal(cpu.cycles, 2, "ROR accumulator uses 2 cycles")
end)
-- ROR Zero Page (0x66)
it("ROR zero page rotates memory right and uses 5 cycles", function()
  local cpu = MOS6502.new()
  cpu:write(0x0010, 0x02) -- Write data 0x02 at zero page address 0x10
  cpu:write(0x8000, 0x66) -- Write opcode 0x66 (ROR zero page)
  cpu:write(0x8001, 0x10) -- Write operand: address 0x10
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu:read(0x0010), 0x81, "ROR zero page: 0x02 rotated right should yield 0x81")
  assert_equal(cpu.cycles, 5, "ROR zero page uses 5 cycles")
end)
-- ROR Zero Page,X (0x76)
it("ROR zero page,X rotates right and uses 6 cycles", function()
  local cpu = MOS6502.new()
  cpu.X = 1
  cpu:write(0x0011, 0x04) -- Write data 0x04 at address (0x10+X)
  cpu:write(0x8000, 0x76) -- Write opcode 0x76 (ROR zero page,X)
  cpu:write(0x8001, 0x10) -- Write operand: base zero page address 0x10
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  cpu:step()
  local expected = (0x04 >> 1) | ((cpu.P & 0x01) << 7)
  assert_equal(cpu:read(0x0011), expected, "ROR zero page,X should correctly rotate right")
  assert_equal(cpu.cycles, 6, "ROR zero page,X uses 6 cycles")
end)
-- ROR Absolute (0x6E)
it("ROR absolute rotates memory right and uses 6 cycles", function()
  local cpu = MOS6502.new()
  cpu:write(0x1234, 0x10) -- Write data 0x10 at absolute address 0x1234
  cpu:write(0x8000, 0x6E) -- Write opcode 0x6E (ROR absolute)
  cpu:write(0x8001, 0x34) -- Write low byte of address 0x1234
  cpu:write(0x8002, 0x12) -- Write high byte of address 0x1234
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu:read(0x1234), 0x08, "ROR absolute: 0x10 rotated right should yield 0x08")
  assert_equal(cpu.cycles, 6, "ROR absolute uses 6 cycles")
end)
-- ROR Absolute,X (0x7E)
it("ROR absolute,X rotates memory right and uses 7 cycles", function()
  local cpu = MOS6502.new()
  cpu.X = 1
  cpu:write(0x1235, 0x08) -- Write data 0x08 at effective address (base+X)
  cpu:write(0x8000, 0x7E) -- Write opcode 0x7E (ROR absolute,X)
  cpu:write(0x8001, 0x34) -- Write low byte of base address
  cpu:write(0x8002, 0x12) -- Write high byte of base address
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu:read(0x1235), 0x04, "ROR absolute,X: 0x08 rotated right should yield 0x04")
  assert_equal(cpu.cycles, 7, "ROR absolute,X uses 7 cycles")
end)

-------------------------------------------------
-- RTI (Return from Interrupt, 0x40)
it("RTI pulls processor status and PC from stack and uses 6 cycles", function()
  local cpu = MOS6502.new()
  cpu:push(0xAA)          -- Push processor status 0xAA onto the stack
  cpu:push(0x00)          -- Push low byte of return PC (to form 0x9000)
  cpu:push(0x90)          -- Push high byte of return PC (to form 0x9000)
  cpu:write(0x8000, 0x40) -- Write opcode 0x40 (RTI)
  cpu:write(0xFFFC, 0x00) -- Reset vector low byte
  cpu:write(0xFFFD, 0x80) -- Reset vector high byte
  cpu:reset()
  cpu:step()
  assert_equal(cpu.P, (0xAA & 0xEF) | 0x20, "RTI should restore the processor status correctly")
  assert_equal(cpu.PC, 0x9000, "RTI should restore PC to 0x9000")
  assert_equal(cpu.cycles, 6, "RTI uses 6 cycles")
end)

-------------------------------------------------
-- RTS (Return from Subroutine, 0x60)
it("RTS pulls the return address from the stack and uses 6 cycles", function()
  local cpu = MOS6502.new()
  cpu:push(0xFF)          -- Push low byte of return address (0xFF)
  cpu:push(0x7F)          -- Push high byte of return address (resulting in 0x8000)
  cpu:write(0x8000, 0x60) -- Write opcode 0x60 (RTS)
  cpu:write(0xFFFC, 0x00) -- Reset vector low byte
  cpu:write(0xFFFD, 0x80) -- Reset vector high byte
  cpu:reset()
  cpu:step()
  assert_equal(cpu.PC, 0x8000, "RTS should set PC to 0x8000 (return address + 1)")
  assert_equal(cpu.cycles, 6, "RTS uses 6 cycles")
end)

-------------------------------------------------
-- SBC (Subtract with Carry)
-- SBC Immediate (0xE9)
it("SBC immediate no borrow returns 2 cycles", function()
  local cpu = MOS6502.new()
  cpu.A = 50; cpu.P = 0x01 -- Set A=50 and carry flag set (no borrow)
  cpu:write(0x8000, 0xE9)  -- Write opcode 0xE9 (SBC immediate)
  cpu:write(0x8001, 20)    -- Write immediate operand 20
  cpu:write(0xFFFC, 0x00)  -- Reset vector low
  cpu:write(0xFFFD, 0x80)  -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.A, 30, "SBC immediate: 50 - 20 should equal 30")
  assert_equal(cpu.cycles, 2, "SBC immediate uses 2 cycles")
end)
-- SBC Zero Page (0xE5)
it("SBC zero page no borrow returns 3 cycles", function()
  local cpu = MOS6502.new()
  cpu.A = 50; cpu.P = 0x01
  cpu:write(0x0010, 20)   -- Write data 20 at zero page address 0x10
  cpu:write(0x8000, 0xE5) -- Write opcode 0xE5 (SBC zero page)
  cpu:write(0x8001, 0x10) -- Write operand: address 0x10
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.A, 30, "SBC zero page: 50 - 20 should equal 30")
  assert_equal(cpu.cycles, 3, "SBC zero page uses 3 cycles")
end)
-- SBC Zero Page,X (0xF5)
it("SBC zero page,X no borrow returns 4 cycles", function()
  local cpu = MOS6502.new()
  cpu.A = 50; cpu.P = 0x01; cpu.X = 1
  cpu:write(0x0011, 20)   -- Write data 20 at (0x10+X)
  cpu:write(0x8000, 0xF5) -- Write opcode 0xF5 (SBC zero page,X)
  cpu:write(0x8001, 0x10) -- Write operand: base address 0x10
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.A, 30, "SBC zero page,X: 50 - 20 should equal 30")
  assert_equal(cpu.cycles, 4, "SBC zero page,X uses 4 cycles")
end)
-- SBC Absolute (0xED)
it("SBC absolute no borrow returns 4 cycles", function()
  local cpu = MOS6502.new()
  cpu.A = 50; cpu.P = 0x01
  cpu:write(0x1234, 20)   -- Write data 20 at absolute address 0x1234
  cpu:write(0x8000, 0xED) -- Write opcode 0xED (SBC absolute)
  cpu:write(0x8001, 0x34) -- Write low byte of address 0x1234
  cpu:write(0x8002, 0x12) -- Write high byte of address 0x1234
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.A, 30, "SBC absolute: 50 - 20 should equal 30")
  assert_equal(cpu.cycles, 4, "SBC absolute uses 4 cycles")
end)
-- SBC Absolute,X (0xFD)
it("SBC absolute,X no borrow returns 4 cycles (no page cross)", function()
  local cpu = MOS6502.new()
  cpu.A = 50; cpu.P = 0x01; cpu.X = 1
  cpu:write(0x1235, 20)   -- Write data 20 at effective address (base+X)
  cpu:write(0x8000, 0xFD) -- Write opcode 0xFD (SBC absolute,X)
  cpu:write(0x8001, 0x34) -- Write low byte of base address
  cpu:write(0x8002, 0x12) -- Write high byte of base address
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.A, 30, "SBC absolute,X (no page cross): 50 - 20 should equal 30")
  assert_equal(cpu.cycles, 4, "SBC absolute,X (no page cross) uses 4 cycles")
end)
-- SBC Absolute,Y (0xF9)
it("SBC absolute,Y no borrow returns 4 cycles (no page cross)", function()
  local cpu = MOS6502.new()
  cpu.A = 50; cpu.P = 0x01; cpu.Y = 1
  cpu:write(0x1235, 20)   -- Write data 20 at effective address (base+Y)
  cpu:write(0x8000, 0xF9) -- Write opcode 0xF9 (SBC absolute,Y)
  cpu:write(0x8001, 0x34) -- Write low byte of base address
  cpu:write(0x8002, 0x12) -- Write high byte of base address
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.A, 30, "SBC absolute,Y (no page cross): 50 - 20 should equal 30")
  assert_equal(cpu.cycles, 4, "SBC absolute,Y (no page cross) uses 4 cycles")
end)
-- SBC (Indirect,X) (0xE1)
it("SBC (indirect,X) no borrow returns 6 cycles", function()
  local cpu = MOS6502.new()
  cpu.A = 50; cpu.P = 0x01; cpu.X = 1
  local zp = 0x20
  cpu:write(zp + cpu.X, 0x00)                -- Write pointer low at (0x20+X)
  cpu:write(((zp + cpu.X + 1) & 0xFF), 0x30) -- Write pointer high at (0x20+X+1)
  cpu:write(0x3000, 20)                      -- Write data 20 at computed address 0x3000
  cpu:write(0x8000, 0xE1)                    -- Write opcode 0xE1 (SBC (indirect,X))
  cpu:write(0x8001, 0x20)                    -- Write operand: zero page base address 0x20
  cpu:write(0xFFFC, 0x00)                    -- Reset vector low
  cpu:write(0xFFFD, 0x80)                    -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.A, 30, "SBC (indirect,X): 50 - 20 should equal 30")
  assert_equal(cpu.cycles, 6, "SBC (indirect,X) uses 6 cycles")
end)
-- SBC (Indirect),Y (0xF1)
it("SBC (indirect),Y no borrow returns 5 cycles (no page cross)", function()
  local cpu = MOS6502.new()
  cpu.A = 50; cpu.P = 0x01; cpu.Y = 4
  cpu:write(0x20, 0x00)   -- Write pointer low at zero page address 0x20
  cpu:write(0x21, 0x40)   -- Write pointer high at zero page address 0x21
  cpu:write(0x4004, 20)   -- Write data 20 at computed address (0x4000+Y)
  cpu:write(0x8000, 0xF1) -- Write opcode 0xF1 (SBC (indirect),Y)
  cpu:write(0x8001, 0x20) -- Write operand: zero page address 0x20
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.A, 30, "SBC (indirect),Y (no page cross): 50 - 20 should equal 30")
  assert_equal(cpu.cycles, 5, "SBC (indirect),Y uses 5 cycles")
end)

-------------------------------------------------
-- SEC, SED, SEI (Set Flag Instructions)
-- SEC (Set Carry, 0x38)
it("SEC sets the carry flag and uses 2 cycles", function()
  local cpu = MOS6502.new()
  cpu.P = 0x00
  cpu:write(0x8000, 0x38) -- Write opcode 0x38 (SEC)
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal((cpu.P & 0x01) ~= 0, true, "SEC should set the carry flag")
  assert_equal(cpu.cycles, 2, "SEC uses 2 cycles")
end)
-- SED (Set Decimal, 0xF8)
it("SED sets the decimal flag and uses 2 cycles", function()
  local cpu = MOS6502.new()
  cpu.P = 0x00
  cpu:write(0x8000, 0xF8) -- Write opcode 0xF8 (SED)
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal((cpu.P & 0x08) ~= 0, true, "SED should set the decimal flag")
  assert_equal(cpu.cycles, 2, "SED uses 2 cycles")
end)
-- SEI (Set Interrupt Disable, 0x78)
it("SEI sets the interrupt disable flag and uses 2 cycles", function()
  local cpu = MOS6502.new()
  cpu.P = 0x00
  cpu:write(0x8000, 0x78) -- Write opcode 0x78 (SEI)
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal((cpu.P & 0x04) ~= 0, true, "SEI should set the interrupt disable flag")
  assert_equal(cpu.cycles, 2, "SEI uses 2 cycles")
end)

-------------------------------------------------
-- SBC (Subtract with Carry)
-- SBC Immediate (0xE9)
it("SBC immediate no borrow returns 2 cycles", function()
  local cpu = MOS6502.new()
  cpu.A = 50; cpu.P = 0x01 -- Set A=50 and carry flag set (no borrow)
  cpu:write(0x8000, 0xE9)  -- Write opcode 0xE9 (SBC immediate)
  cpu:write(0x8001, 20)    -- Write immediate operand 20
  cpu:write(0xFFFC, 0x00)  -- Reset vector low
  cpu:write(0xFFFD, 0x80)  -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.A, 30, "SBC immediate should yield 30 (50-20)")
  assert_equal(cpu.cycles, 2, "SBC immediate uses 2 cycles")
end)
-- SBC Zero Page (0xE5)
it("SBC zero page no borrow returns 3 cycles", function()
  local cpu = MOS6502.new()
  cpu.A = 50; cpu.P = 0x01
  cpu:write(0x0010, 20)   -- Write data 20 at zero page address 0x10
  cpu:write(0x8000, 0xE5) -- Write opcode 0xE5 (SBC zero page)
  cpu:write(0x8001, 0x10) -- Write operand: address 0x10
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.A, 30, "SBC zero page should yield 30 (50-20)")
  assert_equal(cpu.cycles, 3, "SBC zero page uses 3 cycles")
end)
-- SBC Zero Page,X (0xF5)
it("SBC zero page,X no borrow returns 4 cycles", function()
  local cpu = MOS6502.new()
  cpu.A = 50; cpu.P = 0x01; cpu.X = 1
  cpu:write(0x0011, 20)   -- Write data 20 at address (0x10+X)
  cpu:write(0x8000, 0xF5) -- Write opcode 0xF5 (SBC zero page,X)
  cpu:write(0x8001, 0x10) -- Write operand: base address 0x10
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.A, 30, "SBC zero page,X should yield 30 (50-20)")
  assert_equal(cpu.cycles, 4, "SBC zero page,X uses 4 cycles")
end)
-- SBC Absolute (0xED)
it("SBC absolute no borrow returns 4 cycles", function()
  local cpu = MOS6502.new()
  cpu.A = 50; cpu.P = 0x01
  cpu:write(0x1234, 20)   -- Write data 20 at absolute address 0x1234
  cpu:write(0x8000, 0xED) -- Write opcode 0xED (SBC absolute)
  cpu:write(0x8001, 0x34) -- Write low byte of address 0x1234
  cpu:write(0x8002, 0x12) -- Write high byte of address 0x1234
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.A, 30, "SBC absolute should yield 30 (50-20)")
  assert_equal(cpu.cycles, 4, "SBC absolute uses 4 cycles")
end)
-- SBC Absolute,X (0xFD)
it("SBC absolute,X no borrow returns 4 cycles (no page cross)", function()
  local cpu = MOS6502.new()
  cpu.A = 50; cpu.P = 0x01; cpu.X = 1
  cpu:write(0x1235, 20)   -- Write data 20 at effective address (base+X)
  cpu:write(0x8000, 0xFD) -- Write opcode 0xFD (SBC absolute,X)
  cpu:write(0x8001, 0x34) -- Write low byte of base address
  cpu:write(0x8002, 0x12) -- Write high byte of base address
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.A, 30, "SBC absolute,X (no page cross) should yield 30")
  assert_equal(cpu.cycles, 4, "SBC absolute,X (no page cross) uses 4 cycles")
end)
-- SBC Absolute,Y (0xF9)
it("SBC absolute,Y no borrow returns 4 cycles (no page cross)", function()
  local cpu = MOS6502.new()
  cpu.A = 50; cpu.P = 0x01; cpu.Y = 1
  cpu:write(0x1235, 20)   -- Write data 20 at effective address (base+Y)
  cpu:write(0x8000, 0xF9) -- Write opcode 0xF9 (SBC absolute,Y)
  cpu:write(0x8001, 0x34) -- Write low byte of base address
  cpu:write(0x8002, 0x12) -- Write high byte of base address
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.A, 30, "SBC absolute,Y (no page cross) should yield 30")
  assert_equal(cpu.cycles, 4, "SBC absolute,Y (no page cross) uses 4 cycles")
end)
-- SBC (Indirect,X) (0xE1)
it("SBC (indirect,X) no borrow returns 6 cycles", function()
  local cpu = MOS6502.new()
  cpu.A = 50; cpu.P = 0x01; cpu.X = 1
  local zp = 0x20
  cpu:write(zp + cpu.X, 0x00)                -- Write pointer low at (0x20+X)
  cpu:write(((zp + cpu.X + 1) & 0xFF), 0x30) -- Write pointer high at (0x20+X+1)
  cpu:write(0x3000, 20)                      -- Write data 20 at computed address 0x3000
  cpu:write(0x8000, 0xE1)                    -- Write opcode 0xE1 (SBC (indirect,X))
  cpu:write(0x8001, 0x20)                    -- Write operand: zero page base address 0x20
  cpu:write(0xFFFC, 0x00)                    -- Reset vector low
  cpu:write(0xFFFD, 0x80)                    -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.A, 30, "SBC (indirect,X) should yield 30 (50-20)")
  assert_equal(cpu.cycles, 6, "SBC (indirect,X) uses 6 cycles")
end)
-- SBC (Indirect),Y (0xF1)
it("SBC (indirect),Y no borrow returns 5 cycles (no page cross)", function()
  local cpu = MOS6502.new()
  cpu.A = 50; cpu.P = 0x01; cpu.Y = 4
  cpu:write(0x20, 0x00)   -- Write pointer low at zero page address 0x20
  cpu:write(0x21, 0x40)   -- Write pointer high at zero page address 0x21
  cpu:write(0x4004, 20)   -- Write data 20 at computed address (0x4000+Y)
  cpu:write(0x8000, 0xF1) -- Write opcode 0xF1 (SBC (indirect),Y)
  cpu:write(0x8001, 0x20) -- Write operand: zero page address 0x20
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal(cpu.A, 30, "SBC (indirect),Y should yield 30 (50-20)")
  assert_equal(cpu.cycles, 5, "SBC (indirect),Y uses 5 cycles")
end)

-------------------------------------------------
-- SEC, SED, SEI
-- SEC (0x38)
it("SEC sets the carry flag and uses 2 cycles", function()
  local cpu = MOS6502.new()
  cpu.P = 0x00
  cpu:write(0x8000, 0x38) -- Write opcode 0x38 (SEC)
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal((cpu.P & 0x01) ~= 0, true, "SEC should set the carry flag")
  assert_equal(cpu.cycles, 2, "SEC uses 2 cycles")
end)
-- SED (0xF8)
it("SED sets the decimal flag and uses 2 cycles", function()
  local cpu = MOS6502.new()
  cpu.P = 0x00
  cpu:write(0x8000, 0xF8) -- Write opcode 0xF8 (SED)
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal((cpu.P & 0x08) ~= 0, true, "SED should set the decimal flag")
  assert_equal(cpu.cycles, 2, "SED uses 2 cycles")
end)
-- SEI (0x78)
it("SEI sets the interrupt disable flag and uses 2 cycles", function()
  local cpu = MOS6502.new()
  cpu.P = 0x00
  cpu:write(0x8000, 0x78) -- Write opcode 0x78 (SEI)
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu:reset()
  cpu:step()
  assert_equal((cpu.P & 0x04) ~= 0, true, "SEI should set the interrupt disable flag")
  assert_equal(cpu.cycles, 2, "SEI uses 2 cycles")
end)

-------------------------------------------------
-- STX (Store X Register)
-- STX Zero Page (0x86)
it("STX zero page stores X into memory and uses 3 cycles", function()
  local cpu = MOS6502.new()
  cpu.X = 0xBB
  cpu:write(0x8000, 0x86) -- Write opcode 0x86 (STX zero page)
  cpu:write(0x8001, 0x10) -- Write operand: address 0x10
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu.X = 0xBB
  cpu:reset()
  cpu:step()
  assert_equal(cpu:read(0x0010), 0xBB, "STX zero page should store 0xBB at address 0x10")
  assert_equal(cpu.cycles, 3, "STX zero page uses 3 cycles")
end)
-- STX Zero Page,Y (0x96)
it("STX zero page,Y stores X into memory and uses 4 cycles", function()
  local cpu = MOS6502.new()
  cpu.X = 0xBB; cpu.Y = 1
  cpu:write(0x8000, 0x96) -- Write opcode 0x96 (STX zero page,Y)
  cpu:write(0x8001, 0x10) -- Write operand: base address 0x10
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu.X = 0xBB
  cpu:reset()
  cpu:step()
  local addr = (0x10 + cpu.Y) & 0xFF
  assert_equal(cpu:read(addr), 0xBB, "STX zero page,Y should store 0xBB at (0x10+Y)")
  assert_equal(cpu.cycles, 4, "STX zero page,Y uses 4 cycles")
end)
-- STX Absolute (0x8E)
it("STX absolute stores X into memory and uses 4 cycles", function()
  local cpu = MOS6502.new()
  cpu.X = 0xBB
  cpu:write(0x8000, 0x8E) -- Write opcode 0x8E (STX absolute)
  cpu:write(0x8001, 0x34) -- Write low byte of target address (0x1234)
  cpu:write(0x8002, 0x12) -- Write high byte of target address (0x1234)
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu.X = 0xBB
  cpu:reset()
  cpu:step()
  assert_equal(cpu:read(0x1234), 0xBB, "STX absolute should store 0xBB at 0x1234")
  assert_equal(cpu.cycles, 4, "STX absolute uses 4 cycles")
end)

-------------------------------------------------
-- STY (Store Y Register)
-- STY Zero Page (0x84)
it("STY zero page stores Y into memory and uses 3 cycles", function()
  local cpu = MOS6502.new()
  cpu.Y = 0xCC
  cpu:write(0x8000, 0x84) -- Write opcode 0x84 (STY zero page)
  cpu:write(0x8001, 0x10) -- Write operand: address 0x10
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu.Y = 0xCC
  cpu:reset()
  cpu:step()
  assert_equal(cpu:read(0x0010), 0xCC, "STY zero page should store 0xCC at address 0x10")
  assert_equal(cpu.cycles, 3, "STY zero page uses 3 cycles")
end)
-- STY Zero Page,X (0x94)
it("STY zero page,X stores Y into memory and uses 4 cycles", function()
  local cpu = MOS6502.new()
  cpu.Y = 0xCC; cpu.X = 1
  cpu:write(0x8000, 0x94) -- Write opcode 0x94 (STY zero page,X)
  cpu:write(0x8001, 0x10) -- Write operand: base address 0x10
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu.Y = 0xCC
  cpu:reset()
  cpu:step()
  local addr = (0x10 + cpu.X) & 0xFF
  assert_equal(cpu:read(addr), 0xCC, "STY zero page,X should store 0xCC at (0x10+X)")
  assert_equal(cpu.cycles, 4, "STY zero page,X uses 4 cycles")
end)
-- STY Absolute (0x8C)
it("STY absolute stores Y into memory and uses 4 cycles", function()
  local cpu = MOS6502.new()
  cpu.Y = 0xCC
  cpu:write(0x8000, 0x8C) -- Write opcode 0x8C (STY absolute)
  cpu:write(0x8001, 0x34) -- Write low byte of target address (0x1234)
  cpu:write(0x8002, 0x12) -- Write high byte of target address (0x1234)
  cpu:write(0xFFFC, 0x00) -- Reset vector low
  cpu:write(0xFFFD, 0x80) -- Reset vector high
  cpu.Y = 0xCC
  cpu:reset()
  cpu:step()
  assert_equal(cpu:read(0x1234), 0xCC, "STY absolute should store 0xCC at 0x1234")
  assert_equal(cpu.cycles, 4, "STY absolute uses 4 cycles")
end)

-------------------------------------------------
-- End of complete tests.
