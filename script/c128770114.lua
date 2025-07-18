--Cyber Angel Ascension
--Scripted by [Your Name]
local s,id=GetID()
function s.initial_effect(c)
	-- Ritual Summon Cyber Angel Ritual Monster
	local e1=Ritual.CreateProc({
		handler=c,
		filter=aux.FilterBoolFunction(Card.IsSetCard,0x2093), -- "사이버 엔젤"
		lvtype=RITPROC_EQUAL,
		location=LOCATION_HAND+LOCATION_DECK,
		extrafil=s.extrafil,
		extramat=s.extraop,
		level_function=s.rlevel, -- 여기에서 펜듈럼 존 몬스터는 레벨 4로 계산
		description=aux.Stringid(id,0)
	})
	c:RegisterEffect(e1)
end

-- 펜듈럼 존 + 엑스트라 덱 조건부 추가
function s.pzone_filter(c)
	return c:IsFaceup() and c:IsType(TYPE_MONSTER) and c:IsAbleToGrave()
end

function s.extra_filter(c)
	return c:IsFaceup() and c:IsType(TYPE_MONSTER) and c:IsAbleToGrave()
end

function s.extrafil(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.pzone_filter,tp,LOCATION_PZONE,0,nil)
	
	-- 엑스트라 조건 충족 시, 엑스트라 덱 카드도 포함
	if Duel.IsExistingMatchingCard(function(c)
		return c:IsFaceup() and c:IsSummonLocation(LOCATION_EXTRA)
	end, tp, 0, LOCATION_MZONE, 1, nil) then
		local exg=Duel.GetMatchingGroup(s.extra_filter,tp,LOCATION_EXTRA,0,nil)
		local ex_selected=aux.SelectUnselectGroup(exg,e,tp,1,2,aux.dncheck,1,tp,HINTMSG_RELEASE)
		if #ex_selected>0 then g:Merge(ex_selected) end
	end
	return g
end

-- 추가 소재 묘지 처리
function s.extraop(e,tp,eg,ep,ev,re,r,rp,sg,sc,mg,smat,exg)
	if exg then
		Duel.SendtoGrave(exg,REASON_MATERIAL+REASON_RITUAL+REASON_EFFECT)
		sg:Merge(exg)
	end
end

-- 펜듈럼 존 카드가 레벨 4로 간주되도록
function s.rlevel(ritual_mon,mat)
	if mat:IsLocation(LOCATION_PZONE) then
		return 4
	else
		return mat:GetLevel()
	end
end

