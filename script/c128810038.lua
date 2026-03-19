--셀레스티얼 타이탄-탐사자 오네그
local s,id=GetID()
function s.initial_effect(c)
	-- Pendulum Summon
	Pendulum.AddProcedure(c)

	-- E1: 빛 속성만 펜듈럼 소환 가능
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CANNOT_DISABLE)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetRange(LOCATION_PZONE)
	e1:SetTargetRange(1,0)
	e1:SetTarget(s.splimit)
	c:RegisterEffect(e1)

	-- E2: 덱에서 펜듈럼 몬스터를 엑스트라 덱으로
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_PZONE)
	e2:SetCountLimit(1,id)
	e2:SetCost(Cost.PayLP(1500))
	e2:SetTarget(s.tg)
	e2:SetOperation(s.op)
	c:RegisterEffect(e2)
end

s.listed_series={0xc02}
s.listed_names={id}

-- E1 필터: 빛 속성이 아닌 펜듈럼 소환을 막음
function s.splimit(e,c,sump,sumtype,sumpos,targetp,se)
	return c:IsLocation(LOCATION_EXTRA+LOCATION_HAND)
		and (sumtype&SUMMON_TYPE_PENDULUM)==SUMMON_TYPE_PENDULUM
		and not c:IsAttribute(ATTRIBUTE_LIGHT)
end

-- 필터 함수 (펜듈럼 몬스터인지, 엑스트라 덱으로 보낼 수 있는지 확인)
function s.filter(c)
	return c:IsType(TYPE_PENDULUM) and c:IsSetCard(0xc02) -- 카드군 번호에 맞춰 수정
		and not c:IsForbidden() -- 금지된 카드는 엑스트라 덱으로 보낼 수 없음
end

function s.tg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.filter,tp,LOCATION_DECK,0,1,nil) end
end
function s.op(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,aux.Stringid(id,3))
	local g=Duel.SelectMatchingCard(tp,s.filter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoExtraP(g,tp,REASON_EFFECT)
	end
end