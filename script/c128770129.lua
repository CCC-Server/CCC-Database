--트릭스터 하모닉 스테이지
local s,id=GetID()
function s.initial_effect(c)
	-- 발동
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_ACTIVATE)
	e0:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e0)

	--① 엑스트라 덱에서 특수 소환された 트릭스터 몬스터를 덱에서 패로
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetRange(LOCATION_SZONE)
	e1:SetCountLimit(2,id) -- 1턴 2번까지
	e1:SetCondition(s.thcon)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)
end

-- 필터: 자신 필드에 엑스트라 덱에서 특수 소환된 트릭스터
function s.cfilter(c,tp)
	return c:IsSetCard(0xfb) and c:IsSummonLocation(LOCATION_EXTRA) and c:IsControler(tp)
end

function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return eg:IsExists(s.cfilter,1,nil,tp)
end

-- 덱에서 공격력 이하 트릭스터 몬스터 선택 가능 여부
function s.thfilter(c,atk)
	return c:IsSetCard(0xfb) and c:IsMonster() and c:IsAttackBelow(atk) and c:IsAbleToHand()
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local tc=eg:Filter(s.cfilter,nil,tp):GetFirst()
		return tc and Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil,tc:GetAttack())
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local tc=eg:Filter(s.cfilter,nil,tp):GetFirst()
	if not tc then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil,tc:GetAttack())
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
		-- 같은 이름을 "트릭스터 베뉴" 효과로 넣지 못하게 임시 플래그
		g:GetFirst():RegisterFlagEffect(id,RESET_PHASE+PHASE_END,0,1)
	end
	-- 턴 종료까지 엑스트라덱 특수 소환 제한 (링크/융합만 허용)
	local e2=Effect.CreateEffect(e:GetHandler())
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e2:SetTargetRange(1,0)
	e2:SetTarget(s.splimit)
	e2:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e2,tp)
end

-- 엑스트라 덱에서 링크/융합만 허용
function s.splimit(e,c,sump,sumtype,sumpos,targetp,se)
	return c:IsLocation(LOCATION_EXTRA) and not (c:IsType(TYPE_LINK) or c:IsType(TYPE_FUSION))
end

