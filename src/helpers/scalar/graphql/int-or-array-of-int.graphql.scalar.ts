import { GraphQLScalarType } from "graphql";

function validate(input: unknown): unknown {
    const arr = Array.isArray(input) ? input : [input]

    if (arr.some(i => i !== parseInt(i, 10))) {
        throw new Error("invalid int or array int");
    }
    return input;
}

export const CustomIntOrAIntScalar = new GraphQLScalarType({
    name: 'IntOrAInt',
    description: 'Number or Array Number',
    serialize: (value) => validate(value),
    parseValue: (value) => validate(value),
})