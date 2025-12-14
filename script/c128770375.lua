local s,id=GetID()
function s.initial_effect(c)
	-- E1: 패에서 특수 소환 (필드/묘지에 라바르 존재 시)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spcon)
	c:RegisterEffect(e1)

	-- E2: 일반/특수 소환 성공 시 발동 -> 덱에서 "라바르" 카드명 포함 마함 세트
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCountLimit(1,id+1)
	e2:SetTarget(s.settg)
	e2:SetOperation(s.setop)
	c:RegisterEffect(e2)
	local e2b=e2:Clone()
	e2b:SetCode(EVENT_SUMMON_SUCCESS)
	c:RegisterEffect(e2b)

	-- E3: 1턴에 2번까지 -> 라바르 몬스터 1장 덱에서 묘지 + 800 데미지
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_TOGRAVE+CATEGORY_DAMAGE)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCountLimit(2,id+2)
	e3:SetTarget(s.damtg)
	e3:SetOperation(s.damop)
	c:RegisterEffect(e3)
end

-- 🔹E1: 패에서 특수 소환 조건
function s.lavalfilter(c)
	return c:IsSetCard(0x39)
end
function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.IsExistingMatchingCard(s.lavalfilter,tp,LOCATION_GRAVE+LOCATION_ONFIELD,0,1,nil)
end

-- 🔹E2: 소환 성공 시 마함 세트
function s.setfilter(c)
	local listed_ids = {
		[72142276]=true,
		[47658964]=true,
		[37436576]=true,
		[86690572]=true
	}
	return c:IsType(TYPE_SPELL+TYPE_TRAP)
		and c:IsSSetable()
		and (c:IsSetCard(0x39) or listed_ids[c:GetCode()])
end
-- E2: 소환 성공 시 마법/함정 세트
function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK,0,1,nil) end
end

function s.setop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
	local g=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SSet(tp,g:GetFirst())
		Duel.ConfirmCards(1-tp,g)
	end
end


-- 🔹E3: 묘지 보내고 데미지
function s.tgfilter(c)
	return c:IsSetCard(0x39) and c:IsMonster() and c:IsAbleToGrave()
end
function s.damtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.tgfilter,tp,LOCATION_DECK,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)
	Duel.SetOperationInfo(0,CATEGORY_DAMAGE,nil,0,1-tp,800)
end
function s.damop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,s.tgfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 and Duel.SendtoGrave(g,REASON_EFFECT)>0 then
		Duel.Damage(1-tp,800,REASON_EFFECT)
	end
end
