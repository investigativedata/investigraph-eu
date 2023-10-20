from typing import Any

from followthemoney.util import join_text, make_entity_id
from ftmq.util import fingerprint as fp
from investigraph import Context
from investigraph.types import CE, CEGenerator, Record


def make_address(ctx: Context, prefix: str, data: dict[str, Any]) -> CE | None:
    proxy = ctx.make("Address")
    street = data.get("{prefix} office address")
    postalCode = data.get("{prefix} office post code")
    postBox = data.get("{prefix} office post box")
    city = data.get("{prefix} office city")
    country = data.get("{prefix} office country")
    full = join_text(street, postalCode, postBox, city, country, sep=", ")
    proxy.id = ctx.make_slug(make_entity_id(fp(full)), prefix="addr")
    if proxy.id is not None:
        ctx.emit(proxy)
        return proxy


def parse_record(ctx: Context, record: dict[str, Any]):
    schema = "Organization"
    if "company" in record["Form of the entity"]:
        schema = "Company"
    proxy = ctx.make(schema)
    ident = record["Identification code"]
    proxy.id = ctx.make_slug(ident)
    proxy.add("idNumber", ident)
    proxy.add("name", record["Name"])
    proxy.add("alias", record["Acronym"])
    proxy.add("website", record["Website URL"])
    eu_address = make_address(ctx, "Head", record)
    nat_address = make_address(ctx, "EU", record)
    if eu_address is not None:
        proxy.add("address", eu_address.caption)
        proxy.add("addressEntity", eu_address)
    if nat_address is not None:
        proxy.add("country", nat_address.get("country"))
        proxy.add("address", nat_address.caption)
        proxy.add("addressEntity", nat_address)
    proxy.add("phone", record["Head office phone"])
    proxy.add("phone", record["EU office phone"])
    proxy.add("classification", record["Category of registration"].split(","))
    proxy.add("sector", record["Level of interest"].split(","))
    proxy.add("summary", record["Goals"])
    proxy.add("keywords", record["Fields of interest"].split(","))
    description_cols = (
        "Communication activities",
        "EU legislative proposals/policies",
        "Intergroups and unofficial groupings",
        "Unoffical Groups",
        "Expert Groups",
        "Participation in other EU supported forums and platforms",
        "Members Complementary information",
        "Is member of: List of associations, (con)federations, networks or other bodies of which the organisation is a member",  # noqa
        "Organisation Members: List of organisations, networks and associations that are the members and/or  affiliated with the organisation",  # noqa
        "Interests represented",
        "Annual costs for registers activity or total budget",
        "Source of funding",
        "Source of funding (other)",
        "Closed year EU grant: amount (source)",
        "Closed year total EU grants",
        "Closed year: Intermediary (cost) or client (revenue): EU legislative proposal ",  # noqa
        "Current year Intermediary or client",
        "Current year EU grant: source (amount)",
        "Current year total",
        "Complementary information",
    )
    description = "\n\n".join(
        [f"{c}:\n{record[c]}" for c in description_cols if record[c]]
    )
    proxy.add("description", description)

    ctx.emit(proxy)


def parse_agents(ctx: Context, record: dict[str, Any]):
    regId = record.pop("orgIdentificationCode")
    client = ctx.make("Organization")
    client.id = ctx.make_slug(regId)
    client.add("name", record.pop("orgName"))
    client.add("idNumber", regId)
    ctx.emit(client)

    agent = ctx.make("Person")
    title, firstName, lastName = (
        record.pop("title", None),
        record.pop("firstName"),
        record.pop("lastName"),
    )
    agent.add("title", title)
    agent.add("firstName", firstName)
    agent.add("lastName", lastName)
    agent.add("name", join_text(title, firstName, lastName))
    agent.id = ctx.make_slug("agent", regId, make_entity_id(fp(agent.caption)))
    ctx.emit(agent)

    rel = ctx.make("Representation")
    rel.add("agent", agent)
    rel.add("client", client)
    rel.add("role", "Accredited lobbyist to access the european parliament")
    rel.add("startDate", record.pop("accreditationStartDate"))
    rel.add("endDate", record.pop("accreditationEndDate"))
    rel.id = ctx.make_slug(
        "representation", make_entity_id(client.id, agent.id)
    )  # noqa
    ctx.emit(rel)


def handle(ctx: Context, record: Record, ix: int) -> CEGenerator:
    ctx = ctx.task()
    if ctx.source.name == "organizations":
        parse_record(ctx, record)
    elif ctx.source.name == "persons":
        parse_agents(ctx, record)
    else:
        ctx.log.error(f"Unknown source: `{ctx.source.name}`")

    yield from ctx
