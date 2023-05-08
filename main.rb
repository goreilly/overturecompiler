class OvertureCompiler

  VISIBLE = {
    'SPACE_RAT' => 33,
  }

  ROBOT_COMMANDS = {
    'TURN_LEFT' => 0,
    'FORWARD' => 1,
    'TURN_RIGHT' => 2,
    'WAIT' => 3,
    'USE' => 4,
    'SHOOT' => 5,
  }

  OP_MAP = {
    'OR' => 0,
    'NAND' => 1,
    'NOR' => 2,
    'AND' => 3,
    '+' => 4,
    '-' => 5,
  }

  def calc(op)
    op_value = OP_MAP[op]
    raise "Invalid op code: #{op}" if op_value.nil?
    64 | op_value
  end

  ASSIGN_MAP = {
    'SRC' => {
      'r0' => 0,
      'r1' => 8,
      'r2' => 16,
      'r3' => 24,
      'r4' => 32,
      'r5' => 40,
      'input' => 48,
    },
    'DEST' => {
      'r0' => 0,
      'r1' => 1,
      'r2' => 2,
      'r3' => 3,
      'r4' => 4,
      'r5' => 5,
      'output' => 6,
    },
  }

  def assign(src, dest)
    x = ASSIGN_MAP['SRC'][src]
    y = ASSIGN_MAP['DEST'][dest]

    raise "Invalid src: #{src}" if x.nil?
    raise "Invalid dest: #{dest}" if y.nil?

    128 | x | y
  end

  JUMP_OPS = {
    'jnever' => 0, # not useful
    'je0' => 1,
    'jlt0' => 2,
    'jlte0' => 3,
    'jmp' => 4,
    'jneq0' => 5,
    'jgte0' => 6,
    'jgt0' => 7,
  }

  def jump_code(op)
    x = JUMP_OPS[op]
    raise "Unknown jump op #{op}" if x.nil?
    192 | x
  end

  def immediate(value, const_defs, label_defs)

    if label_defs.include?(value)
      x = value
      return x
    end

    if const_defs.key?(value)
      n = const_defs[value].to_i
      # puts "const def... #{value} #{n}"
      if n
        return n
      end
    end

    if value.start_with?('ROBOT_')

      tail = value['ROBOT_'.length..]

      x = ROBOT_COMMANDS[tail]
      if x
        return x
      end
      # puts tail

    end

    if /^\d+$/.match(value)
      return value.to_i
    end

    raise "Unknown immediate value #{value}"
  end

  def compile(code)
    # code = File.read('05_maze.txt')

    overture_code = []

    lines = code.lines

    lines.map!(&:strip)
    lines.reject! { |l| l == '' }

    const_defs = {}
    label_defs = []

    lines.each do |line|

      line.strip!

      if line.start_with?('#')
        # a comment
        next
      end



      if (m = /^const (.+?) (.+?)$/.match(line))
        name, value = m.captures
        const_defs[name] = value
        overture_code << line
      elsif (m = /^label (.+?)$/.match(line))
        label_name = m.captures[0]
        label_defs << label_name
        overture_code << line
      elsif (m = /^(r0) = (.+?)$/.match(line))
        # immediate
        assignee, value = m.captures
        raise "assignee must be r0" unless assignee == 'r0'
        code = immediate(value, const_defs, label_defs)
        overture_code << "#{code} # #{line}"
      elsif (m = /^(j\w+)/.match(line))
        # jump equals zero
        jump_op = m.captures[0]

        code = jump_code(jump_op)
        overture_code << "#{code} # #{line}"


      elsif (m = /^(.+?) = (.+?) ([+\-]|AND|OR) (.+?)$/.match(line))
        assignee, op1, op, op2 = m.captures
        raise "assignee must be r3" unless assignee == 'r3'
        raise "op1 must be r1" unless op1 == 'r1'
        raise "op2 must be r2" unless op2 == 'r2'

        code = calc(op)
        overture_code << "#{code} # #{line}"
        # puts [code, 'calc', assignee, op1, op, op2, code].join(' ')
      elsif (m = /^(.+?) = (.+?)$/.match(line))
        op1, op2 = m.captures
        code = assign(op2, op1)
        overture_code << "#{code} # #{line}"
        # puts [code, 'assign', op1, op2, code].join(' ')
      else
        warn "ERROR: #{line}"
      end

    rescue => err
      warn "Failed to parse line: #{line}"
      warn err
      raise err
    end
    # puts '-------'

    overture_code

  end


end

if __FILE__ == $0
  puts OvertureCompiler.new.compile(ARGF.read)
end
